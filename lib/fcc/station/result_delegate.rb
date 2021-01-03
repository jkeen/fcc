require 'active_support/inflector'

module FCC
  module Station
    class ResultDelegate
      def initialize(result)
        @result = result
      end

      def method_missing(m, *args, &block)
        if @result
          matched_key = @result.keys.detect { |d| m.to_s == d.to_s } || @result.keys.detect { |d| m.to_s == d.underscore.to_s }

          if matched_key
            @result[matched_key]
          else
            super
          end
        end
      end
    end
  end
end