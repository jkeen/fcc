require 'httparty'
require_relative './extended_info/parser'
require 'byebug'
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
          puts "loading up cache with all results"
          yield
        end
      end
    end
  end
end