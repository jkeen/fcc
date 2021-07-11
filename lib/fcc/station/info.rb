require 'httparty'

module FCC
  module Station
    class Info
      include HTTParty
      base_uri 'publicfiles.fcc.gov'

      attr_accessor :results, :service

      def initialize(service)
        @service = service
      end

      def find(id_or_call_sign, options = {})
        id = if id_or_call_sign =~ /^\d+$/
               id_or_call_sign
             else
               Station.index(service).call_sign_to_id(id_or_call_sign)
             end

        response = self.class.get("/api/service/#{service.to_s.downcase}/facility/id/#{id}.json")

        begin
          response['results']['facility']
        rescue StandardError => e
          return nil
        end
      end
    end
  end
end