require 'httparty'
require_relative './extended_info/parser'
require 'byebug'
require 'lightly'

module FCC
  module Station
    class Cache
      attr_reader :store

      def initialize(service)
        @service = service
        @store = Station::ExtendedInfo.new(@service)
        @lightly = Lightly.new dir: "tmp/fcc_#{@service}_data", life: '7d', hash: true
      end

      def find(fcc_id)
        results.filter { |r| r[:fcc_id].to_s == fcc_id.to_s }
      end

      def results
        @lightly.get @service.to_s do
          puts "loading up cache with all results"
          @store.all_results.parsed_response
        end
      end

      def inspect
        "<Cache @service=#{service}>"
      end
    end
  end
end