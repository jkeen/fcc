module FCC
  module Query
    class AM < Base
      include Adapters::AM

      def initialize(conditions)
        @base_url = 'http://www.fcc.gov/fcc-bin/amq'
        super
      end
    end
  end
end
