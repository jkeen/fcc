require 'active_support/inflector'

module FCC
  module Station
    class RecordGroup
      def initialize(results = [])
        @results = results.map do |result| 
          result.is_a?(RecordDelegate) ? result : RecordDelegate.new(result)
        end
      end

      def to_json
        return {}.tap do |record|
          [Station::Result::EXTENDED_ATTRIBUTES | Station::Result::BASIC_ATTRIBUTES].flatten.each do |attr|
            record[attr.to_sym] = result_attribute(attr.to_sym)
          end

          %i[contact owner community].each do |attr|
            result = result_attribute(attr.to_sym)
            next unless result

            record[attr] ||= if result.is_a?(Struct)
                               result.to_h.compact
                             elsif result.is_a?(Array) && result.compact.size > 0
                               result
                             elsif result.present?
                               result.to_s
                             end
          end
        end
      end

      def result_attribute(attr)
        @results.collect { |r| r.send(attr.to_sym) }.compact.first
      end

      def method_missing(m, *args, &block)
        result = result_attribute(m.to_sym)

        if result.is_a?(Array) && result.size == 1 
          result = result.first
        end

        result
      end

    end
  end
end