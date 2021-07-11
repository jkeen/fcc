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

        results = @result.collect do |res|
          find_result(res, m)
        end.uniq

        results.size == 1 ? results.first : results
      end

      private

      def find_result(result, name)
        matched_key = result.keys.detect { |d| name.to_s == d.to_s } || result.keys.detect { |d| name.to_s == d.to_s.underscore }

        if matched_key
          result[matched_key]
        else
          nil
        end
      end
    end
  end
end