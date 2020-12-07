require 'active_support'
require_relative 'station/result_delegate'
require_relative 'station/extended_info'
require_relative 'station/index'
require_relative 'station/info'

module FCC
  module Station
    Contact = Struct.new(:name, :title, :address, :address2, :city, :state, :zip_code, :phone, :fax, :email, :website, keyword_init: true)
    Community = Struct.new(:city, :state, keyword_init: true)

    def self.find(service, call_sign)
      Result.new(service, call_sign)
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

    class Result
      EXTENDED_ATTRIBUTES = %i[signal_strength latitude longitude coordinates station_class file_number effective_radiated_power haat_horizontal haat_vertical] # these take a long time to query
      BASIC_ATTRIBUTES    = %i[id call_sign status rf_channel license_expiration_date facility_type frequency]

      delegate *EXTENDED_ATTRIBUTES, to: :extended_data 
      delegate *BASIC_ATTRIBUTES, to: :data

      alias_method :channel, :rf_channel

      def initialize(service, call_sign)
        @call_sign = call_sign.upcase
        @service = service

        data
      end

      def to_json
        {}.tap do |hash|
          [EXTENDED_ATTRIBUTES | BASIC_ATTRIBUTES | %i[contact owner community]].flatten.each do |attr|
            result = send(attr.to_sym)
            if result.respond_to?(:to_h)
              hash[attr] = result.to_h
            else
              hash[attr] = result.to_s
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

      def contact
        contact = data.mainStudioContact
        @contact ||= Contact.new(name: contact['contactName'], title: contact['contactTitle'], address: contact['contactAddress1'], address2: contact['contactAddress2'], city: contact['contactCity'], state: contact['contactState'], zip_code: contact['contactZip'], phone: contact['contactPhone'], fax: contact['contactFax'], email: contact['contactEmail'], website: contact['contactWebsite'])
      end

      def coordinates
        [latitude.to_f, longitude.to_f].to_json
      end

      def coordinates_url
        "https://www.google.com/maps/search/#{coordinates[0]},#{coordinates[1]}"
      end

      def extended_data_url
        "https://transition.fcc.gov/fcc-bin/#{@service.to_s.downcase}q?list=4&facid=#{id}"
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