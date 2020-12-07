require 'httparty'
require 'byebug'
require_relative './extended_info/parser'

module FCC
  module Station
    class ExtendedInfo
      include HTTParty
      base_uri 'www.fcc.gov/fcc-bin'

      attr_accessor :results, :service

      def initialize(service)
        @service = service
        @options = {
          follow_redirects: true
        }
        @query = {
          # state: nil,
          # call: nil,
          # city: nil,
          # arn: nil,
          serv: service.to_s.downcase,
          vac: 3, # licensed records only
          # freq: @service.to_sym == :fm ? '87.1' : '530',
          # fre2: @service.to_sym == :fm ? '107.9' : '1700',
          # facid: nil,
          # class: nil,
          # dkt:   nil,
          # dist:  nil,
          # dlat2: nil,
          # dlon2: nil,
          # mlon2: nil,
          # mlat2: nil,
          # slat2: nil,
          # slon2: nil,
          # NS: "N",
          # e: 9,
          # EW: 'W',
          list: 4, # pipe separated output
          size: 9
        }
      end

      def find(id_or_call_sign)
        if id_or_call_sign =~ /^\d+$/
          id = id_or_call_sign
        else
          id = FCC::Station.index(@service).call_sign_to_id(id_or_call_sign)
        end

        @results ||= begin
          response = self.class.get("/#{service.to_s.downcase}q", @options.merge(query: @query.merge(facid: id)))

          puts response.request.uri.to_s.gsub('&list=4', '&list=0')
          puts response.inspect
          result = response.first
          result['source_url'] = response.request.uri.to_s.gsub('&list=4', '&list=0')
          result
        end
      end

      parser FCC::Station::ExtendedInfoParser
    end
  end
end