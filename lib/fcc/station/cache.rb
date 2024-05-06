require 'httparty'
require_relative './parsers/extended_info'
require 'lightly'
require 'logger'

module FCC
  module Station
    class Cache
      attr_reader :store

      def initialize
        @lightly = Lightly.new(life: '3d', hash: true).tap do |cache|
          cache.prune
        end
      end

      def flush
        @lightly.flush
      end

      def fetch(key)
        FCC.log("Retreiving #{key} from cache")
        @lightly.get(key.to_s) do
          FCC.log "Loading up the cache with results for key: #{key}. This might take a minute…"
          value = yield
          if value
            value
          else
            nil
          end
        end
      end
    end
  end
end