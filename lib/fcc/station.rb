require 'active_support'
require_relative 'station/result_delegate'
require_relative 'station/extended_info'
require_relative 'station/info'

module FCC
  module Station
    Contact = Struct.new(:name, :title, :address, :address2, :city, :state, :zip_code, :phone, :fax, :email, :website, keyword_init: true)

    def self.new(*args)
      Result.new(*args)
    end

    def self.find(type, call_sign)
      
    end

    class Result
      EXTENDED_ATTRIBUTES = %i[signal_strength latitude longitude station_class]
      ATTRIBUTES = %i[id call_sign status rf_channel license_expiration_date community_city community_state facility_type frequency party_name party_address1 party_address2 party_city party_zip1 party_zip2 party_phone main_studio_contact]


      delegate :signal_strength, :latitude, :longitude, :station_class, to: :extended_data 
      delegate :id, :call_sign, :status, :rf_channel, :license_expiration_date, :facility_type, :frequency, :party_name, to: :data

      def initialize(band, call_sign)
        @call_sign = call_sign.upcase
        @band = band
      end

      def attributes
        %i[
          signal_strength latitude longitude coordinates station_class
          id call_sign status rf_channel license_expiration_date facility_type frequency contact owner community
        ]
      end

      def owner
        @owner ||= Contact.new(name: data.partyName, address: data.partyAddress1, address2: data.partyAddress2, city: data.partyCity, state: data.partyState, zip_code: data.partyZip1, phone: data.partyPhone)
      end

      def community
        @owner ||= Contact.new(city: data.communityCity, state: data.communityState)
      end

      def contact
        contact = data.mainStudioContact
        @contact ||= Contact.new(name: contact['contactName'], title: contact['contactTitle'], address: contact['contactAddress1'], address2: contact['contactAddress2'], city: contact['contactCity'], state: contact['contactState'], zip_code: contact['contactZip'], phone: contact['contactPhone'], fax: contact['contactFax'], email: contact['contactEmail'], website: contact['contactWebsite'])
      end

      def coordinates
        [latitude.to_f, longitude.to_f]
      end

      def coordinates_url
        "https://www.google.com/maps/search/#{coordinates[0]},#{coordinates[1]}"
      end

      def extended_data
        @extended_data ||= ResultDelegate.new(ExtendedInfo.new(@band).find(@call_sign))
      end

      def data
        @data ||= ResultDelegate.new(Info.new(@band).find(@call_sign))
      end
    end
  end
end


# @call_letters="KGSR", @frequency="93.3", @band="FM", @channel="227", @station_class="C2", @status="CP", @city="CEDAR PARK", @state="TX", @country="US", @file_number="BPH-20180523AAK", @signal_strength="50.0 kW", @fcc_id="23604", @latitude="30.23", @longitude="-97.50", @licensed_to="WATERLOO MEDIA GROUP, L.P.">, #<FCC::Query::Result:0x00007fb6530d3200 @call_letters="KGSR", @frequency="93.3", @band="FM", @channel="227", @station_class="C", @status="LIC", @city="CEDAR PARK", @state="TX", @country="US", @file_number="BMLH-20140306AHQ", @signal_strength="100.0 kW", @fcc_id="23604", @latitude="30.43", @longitude="-97.59", @licensed_to="WATERLOO MEDIA GROUP, L.P."