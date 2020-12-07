require 'httparty'
require 'byebug'

module FCC
  module Station
    class Info
      include HTTParty
      base_uri 'publicfiles.fcc.gov'

      attr_accessor :results, :service

      def initialize(service)
        @service = service
      end

      def index
        @index ||= begin
          response = self.class.get("/api/service/#{service.to_s.downcase}/facility/getall.json")
          response.parsed_response['results']['facilityList']
        end
      end

      def find(id_or_call_sign)
        if id_or_call_sign =~ /^\d+$/
          id = id_or_call_sign
        else
          id = call_sign_to_id(id_or_call_sign)
        end

        @results ||= begin
          response = self.class.get("/api/service/#{service.to_s.downcase}/facility/id/#{id}.json")
          response['results']['facility']
        end
      end

      def call_sign_to_id(call_sign)
        found = index.detect do |hash|
          hash['callSign'] == call_sign.upcase
        end

        found ||= index.detect do |hash|
          hash['callSign'] == "#{call_sign.upcase}-#{service.to_s.upcase}"
        end

        found['id'] if found
      end
    end
  end
end