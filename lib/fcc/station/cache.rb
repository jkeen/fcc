require 'httparty'
require 'byebug'
require_relative './extended_info/parser'

module FCC
  module Station
    class Cache
      attr_reader :store

      def initialize(service)
        @service = service
        @store = Station::ExtendedInfo.new(@service)
      end

      def find(fcc_id)
        results.detect { |r| r[:fcc_id].to_s == fcc_id.to_s }
      end

      def results
        #TODO: add redis caching tie-in because this query is molasses
        @store.all_results.parsed_response
      end

      def inspect
        "<Cache @service=#{service}>"
      end
    end
  end
end