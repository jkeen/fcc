require 'faraday'
require_relative './base'
require_relative './result'
require 'byebug'
require 'faraday_middleware'
require 'faraday/detailed_logger'
require 'faraday-cookie_jar'

module FCC
  module Query
    class Base
      attr_accessor :conditions

      def initialize(conditions)
        @conditions = conditions
      end

      def results
        @results ||= begin
          connection = Faraday.new(@base_url, request: { timeout: 20 }) { |faraday|
            faraday.response :detailed_logger # <-- Inserts the logger into the connection.
            faraday.adapter :net_http
            faraday.use :cookie_jar
            faraday.use FaradayMiddleware::FollowRedirects
          }
          # A buffer to store the streamed data
          response = connection.get(@base_url) do |req|
            req.headers['Content-Type'] = 'text/html'
            req.params = build_query(conditions)

            # Set a callback which will receive tuples of chunk Strings
            # and the sum of characters received so far
            # req.options.on_data = proc { |chunk, overall_received_bytes|
            #   puts "Received #{overall_received_bytes} characters"
            #   puts chunk
            # }
          end
          results = []
          response.body.each_line do |row|
            fields = row.split('|').select { |field| (field.strip! && !field.nil?) }
            next if discard_result?(fields)

            results << Result.new(parse_results(fields))
          end

          if conditions[:call_letters]
            exact_matches = results.select do |d|
              d.call_letters.downcase == conditions[:call_letters].downcase
            end

            results = exact_matches if exact_matches
          end

          results.sort_by(&:signal_strength).reverse
        end
      end

      protected

      # Implemented in subclass
      def discard_result?
        false
      end

      def parse_results(result)
        raise ArgumentError "needs to be defined in subclass"
      end

      def build_query(params)
        raise ArgumentError "needs to be defined in subclass"
      end

      def output_attributes
        %i[frequency call_letters band channel fm_status latitude longitude file_number station_class fcc_id city state country licensed_to signal_strength]
      end
    end
  end
end