require 'httparty'
require_relative './parsers/extended_info'
require 'lightly'

module FCC
  module Station
    class Cache
      attr_reader :store

      def initialize
        @lightly = Lightly.new dir: FCC::TMP_DIR, life: '3d', hash: true
      end

      def fetch key
        @lightly.get key.to_s do
          puts "Loading up the cache with results from query: #{key}. This might take a while, but after that you're good for a while"
          yield
        end
      end
    end
  end
end