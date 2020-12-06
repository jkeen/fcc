# frozen_string_literal: true
module FCC
  module Query
    class FM < Base
      include Adapters::FM 
      def initialize(conditions)
        @base_url = 'http://www.fcc.gov/fcc-bin/fmq'
        super
      end
    end
  end
end
