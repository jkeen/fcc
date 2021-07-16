require 'httparty'
require 'byebug'
require_relative './extended_info/parser'

module FCC
  module Station
    class ExtendedInfo
      include HTTParty
      attr_accessor :results, :service

      base_uri 'https://transition.fcc.gov/fcc-bin/'

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
          serv: service.to_s.downcase, # Only return primary main records, no backup transmitters, etc… for now
          status: 3, # licensed records only
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

      def all_results
        begin
          cache_key = "#{self.class.instance_variable_get('@default_options')[:base_uri]}/#{@service.to_s.downcase}q"
          FCC.cache.fetch cache_key do
            response = self.class.get("/#{service.to_s.downcase}q", @options.merge(query: @query))
            puts response.request.uri.to_s.gsub('&list=4', '&list=0')
            response.parsed_response
          end
        rescue StandardError => e
          puts e.message
          puts e.backtrace
        end
      end

      def find(id_or_call_sign)
        if id_or_call_sign =~ /^\d+$/
          id = id_or_call_sign
        else
          id = FCC::Station.index(@service).call_sign_to_id(id_or_call_sign)
        end

        begin
          all_results.filter { |r| r[:fcc_id].to_s == id.to_s }
        rescue StandardError => e
          response = self.class.get("/#{service.to_s.downcase}q", @options.merge(query: @query.merge(facid: id)))
          puts response.request.uri.to_s.gsub('&list=4', '&list=0')
          response&.parsed_response
        end
      end

      parser FCC::Station::ExtendedInfoParser
    end
  end
end