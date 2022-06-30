require 'active_support/core_ext/module/delegation'
require_relative 'station/result_delegate'
require_relative 'station/extended_info'
require_relative 'station/index'
require_relative 'station/info'

module FCC
  module Station
    Contact = Struct.new(:name, :title, :address, :address2, :city, :state, :zip_code, :phone, :fax, :email, :website, keyword_init: true)
    Community = Struct.new(:city, :state, keyword_init: true)

    def self.find_each(service, &block)
      results = index(service).results

      results.each do |result|
        yield find(service, result['callSign'])
      end
    end

    def self.find(service, call_sign, options = {})
      Result.new(service, call_sign, options)
    end

    def self.index(service)
      case service.to_s.downcase.to_sym
      when :fm
        @fm_index ||= Index.new(:fm)
      when :am
        @am_index ||= Index.new(:am)
      when :tv
        @tv_index ||= Index.new(:tv)
      else
        raise "unsupported service #{service}. :fm, :am, and :tv are valid"
      end
    end

    def self.extended_info_cache
      @cache ||= Station::Cache.new
    end

    class Result
      EXTENDED_ATTRIBUTES = %i[signal_strength latitude longitude station_class file_number effective_radiated_power haat_horizontal haat_vertical antenna_type] # these take a long time to query
      BASIC_ATTRIBUTES    = %i[id call_sign status rf_channel license_expiration_date facility_type frequency]

      delegate *EXTENDED_ATTRIBUTES, to: :extended_data 
      delegate *BASIC_ATTRIBUTES, to: :data

      alias_method :channel, :rf_channel

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
        data.instance_variable_get('@result')
      end

      def to_json
        {}.tap do |hash|
          [EXTENDED_ATTRIBUTES | BASIC_ATTRIBUTES | %i[contact owner community]].flatten.each do |attr|
            result = send(attr.to_sym)
            next unless result

            hash[attr] = if result.is_a?(Struct)
                          result.to_h
                         elsif result.is_a?(Array) && result.compact.size > 0
                          result
                         elsif result.present?
                          result.to_s
                         end
          end
        end
      end

      def owner
        @owner ||= Contact.new(name: data.partyName, address: data.partyAddress1, address2: data.partyAddress2, city: data.partyCity, state: data.partyState, zip_code: data.partyZip1, phone: data.partyPhone)
      end

      def community
        @community ||= Community.new(city: data.communityCity, state: data.communityState)
      end

      def operating_hours
        extended_data.am_operating_time if @service == :am
      end

      def contact
        contact = data&.mainStudioContact

        return unless contact
        @contact ||= Contact.new(name: contact['contactName'], title: contact['contactTitle'], address: contact['contactAddress1'], address2: contact['contactAddress2'], city: contact['contactCity'], state: contact['contactState'], zip_code: contact['contactZip'], phone: contact['contactPhone'], fax: contact['contactFax'], email: contact['contactEmail'], website: contact['contactWebsite'])
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

      def extended_data
        @extended_data ||= ResultDelegate.new(ExtendedInfo.new(@service).find(@call_sign))
      end

      def data
        @data ||= ResultDelegate.new(Info.new(@service).find(@call_sign))
      end
    end
  end
end