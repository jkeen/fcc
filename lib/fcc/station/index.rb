require 'httparty'
module FCC
  module Station
    class Index
      include HTTParty
      base_uri 'https://publicfiles.fcc.gov'

      attr_accessor :service

      def initialize(service)
        @service = service
      end

      def call_sign_to_id(call_sign)
        found = results.detect do |hash|
          hash['callSign'] == call_sign.upcase
        end

        found ||= results.detect do |hash|
          hash['callSign'] == "#{call_sign.upcase}-#{service.to_s.upcase}"
        end

        found['id'] if found
      end

      def inspect
        "<Station::Index @results=[#{results.size}]>"
      end

      def results
        @results ||= begin
          response = self.class.get("/api/service/#{service.to_s.downcase}/facility/getall")
          response.parsed_response['results']['facilityList']
        end
      end
    end
  end
end