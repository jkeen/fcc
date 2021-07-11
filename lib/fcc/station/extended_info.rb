require 'httparty'
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

      def all_results
        @all_results ||= begin
          puts "charging cache for #{service} extended info"
          response = self.class.get("/#{service.to_s.downcase}q", @options.merge(query: @query))
          puts response.request.uri.to_s.gsub('&list=4', '&list=0')
          response
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

        findings = begin
          FCC::Station.extended_info_cache(@service).find(id)
        rescue StandardError
          response = self.class.get("/#{service.to_s.downcase}q", @options.merge(query: @query.merge(facid: id)))
          puts response.request.uri.to_s.gsub('&list=4', '&list=0')

          response
        end

        return findings.first if findings.size == 1

        keys = findings.collect(&:keys).flatten.uniq

        {}.tap do |result|
          keys.each do |key|
            result[key] = response.collect { |finding| finding[key] }.flatten.uniq.join(' / ')
          end
        end
      end

      parser FCC::Station::ExtendedInfoParser
    end
  end
end