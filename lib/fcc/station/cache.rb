require 'httparty'
require_relative './extended_info/parser'
require 'lightly'

module FCC
  module Station
    class Cache
      attr_reader :store

      def initialize
        @lightly = Lightly.new dir: "tmp/fcc_#{@service}_data", life: '3d', hash: true
      end

      def fetch key
        @lightly.get key.to_s do
          puts "loading up cache with all results. this takes a while, but is way quicker than one-off querying this ancient API"
          yield
        end
      end
    end
  end
end