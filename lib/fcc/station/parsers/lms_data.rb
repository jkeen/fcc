require 'httparty'

module FCC
  module Station
    module Parsers
      class LmsData < HTTParty::Parser
        def parse
          body
        end
      end
    end
  end
end