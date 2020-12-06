module FCC
  module Query
    class Result
      attr_accessor :frequency, :call_letters, :band, :channel, :status, :latitude, :longitude, :file_number, :station_class, :fcc_id, :city, :state, :country, :licensed_to, :signal_strength

      def initialize(options = {})
        options.each do |k,v|
          send("#{k}=", v)
        end
      end
    end
  end
end