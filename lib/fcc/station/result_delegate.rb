require 'active_support/inflector'

module FCC
  module Station
    class ResultDelegate
      def initialize(result)
        @result = result
      end

      def method_missing(m, *args, &block)
        return find_result(@result, m) unless @result.is_a?(Array)
        return find_result(@result.first, m) if @result.size == 1

        filtered_results = @result.filter { |result|
          result[:status] == 'LIC' # Licensed only, no construction permits
        }

        filtered_results = filtered_results.collect { |res|
          find_result(res, m)
        }.uniq

        filtered_results.size == 1 ? filtered_results.first : filtered_results
      end

      private

      def find_key(result, name)
        result&.keys&.detect { |d| name.to_s == d.to_s } || result&.keys&.detect { |d| name.to_s == d.to_s.underscore }
      end

      def find_result(result, name)
        matched_key = find_key(result, name)

        if matched_key
          result[matched_key]
        else
          nil
        end
      end
    end
  end
end