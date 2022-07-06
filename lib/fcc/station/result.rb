module FCC
  module Station
    class Result
      EXTENDED_ATTRIBUTES = %i[band signal_strength latitude longitude station_class file_number effective_radiated_power haat_horizontal haat_vertical antenna_type operating_hours licensed_to city state country] # these take a long time to query
      BASIC_ATTRIBUTES    = %i[id call_sign status rf_channel license_expiration_date facility_type frequency band ]

      def initialize(service, call_sign, options = {})
        @call_sign = call_sign.upcase
        @service = service
        @options = options

        data
      end

      def details_available?
        exists? && data.latitude.present?
      end

      def licensed?
        exists? && data.status == 'LICENSED' && data.license_expiration_date && Time.parse(data.license_expiration_date) > Time.now
      end

      def exists?
        grouped_records.any?
      end

      def to_json
        [].tap do |records|
          grouped_records.each do |rg|
            records << rg.to_json
          end
        end.flatten.compact.uniq
      end

      def coordinates_url
        "https://www.google.com/maps/search/#{latitude},#{longitude}" if latitude.present? && longitude.present?
      end

      def extended_data_url
        "https://transition.fcc.gov/fcc-bin/#{@service.to_s.downcase}q?list=4&facid=#{id}"
      end

      def enterprise_data_url
        "https://enterpriseefiling.fcc.gov/dataentry/public/tv/publicFacilityDetails.html?facilityId=#{id}"
      end

      def data
        @data ||= RecordDelegate.new(Info.new(@service).find(@call_sign))
      end
      alias public_data data

      def method_missing(m, *args, &block)
        service = if @service == :fm
                  fm_record = grouped_records.find { |gr| FCC::FM_FULL_SERVICE == gr.band.upcase }
                  fm_low_power = grouped_records.find { |gr| FCC::FM_LOW_POWER == gr.band.upcase }
                  fm_booster = grouped_records.find { |gr| FCC::FM_BOOSTER == gr.band.upcase }
                  fm_translator = grouped_records.find { |gr| FCC::FM_TRANSLATOR == gr.band.upcase }

                  [fm_record, fm_low_power, fm_booster, fm_translator].compact.find { |r| r.send(m.to_sym) }
                else
                  grouped_records.find { |r| r.send(m.to_sym)  }
                end

        result = service.send(m.to_sym) if service

        if result.is_a?(Array) && result.size == 1 
          result = result.first
        end

        result
      end

      def grouped_records
        grouped = all_records.group_by do |record| 
          [record.id, record.call_sign, record.band, record.frequency].compact.join("/")
        end

        [].tap do |res|
          grouped.each do |key, values|
            res << RecordGroup.new(values)
          end
        end
      end
      alias records grouped_records

      def all_records
        [public_records, transition_records].flatten.compact.filter { |f| f.has_data? }
      end

      private

      def public_records
        public_data_info.map { |r| RecordDelegate.new(r) }
      end

      def transition_records
        transition_data_info.map { |r| RecordDelegate.new(r) }
      end

      def public_data_info
        @public_data_info ||= [Info.new(@service).find(@call_sign)]
      end

      def transition_data_info
        @transition_data_info ||= ExtendedInfo.new(@service).find(@call_sign)
      end
    end
  end
end