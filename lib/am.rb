require 'open-uri'

module FCC
  class AM
    class Station
      attr_reader :call_letters, :band, :hours, :file_number, :station_class, :fcc_id, :city, :state, :country, :licensed_to, :latitude, :longitude
      def initialize(*fields)
        @raw =                fields
        @call_letters =       fields[0]
        @frequency =          fields[1]
        @band =               fields[2]
        #                     fields[3]  # Not used for AM
        #                     fields[4]  # Directional Antenna (DA) or NonDirectional (ND)
        @hours =              fields[5]  # Hours of operation for this record (daytime, nighttime, or unlimited)
        @domestic_class =     fields[6]  # Domestic US Station class
        @international_class =fields[7]  # International station class
        @fm_status =          fields[8]
        @city =               fields[9]
        @state =              fields[10]
        @country =            fields[11]
        @file_number =        fields[12] # File Number (Application, Construction Permit or License) or Docket Number (Rulemaking)
        @signal_strength =    fields[13] # Power
        #                     fields[14] # Not used
        #                     fields[15] # Not used
        #                     fields[16] # Not used
        @fcc_id =             fields[17] # Facility ID Number (unique to each station)
        @latitude =           latitude(fields[18], fields[19], fields[20], fields[21])
        @longitude =          longitude(fields[22], fields[23], fields[24], fields[25])

        @licensed_to =        fields[26] # Licensee or Permittee
        #                     fields[27] # Kilometers distant (radius) from entered latitude, longitude
        #                     fields[28] # Miles distant (radius) from entered latitude, longitude
        #                     fields[29] # Azimuth, looking from center Lat, Lon to this record's Lat, Lon
        #                     fields[30] # Application ID number (from CDBS database)***
      end
      
      private 
      
      def longitude(direction, degrees, minutes, seconds)
        "#{(direction =~ /S/ ? "-" : "")}#{degrees}.#{minutes}"
      end

      def latitude(direction, degrees, minutes, seconds)
        "#{(direction =~ /S/ ? "-" : "")}#{degrees}.#{minutes}"
      end

      def signal_strength(raw_signal)
        raw_signal.gsub(/\.\s+/, ".0 ") if raw_signal
      end

      def frequency(freq)
        freq[/[0-9]+\.?[0-9]/] if freq
      end
    end

    BASE_URL = "http://www.fcc.gov/fcc-bin/amq"

    def self.find(call_letters)
      raise ArgumentError, "no call letters were supplied" if call_letters.nil? || call_letters.strip.length == 0

      find_all(:call_letters => call_letters).first
    end

    def self.find_all(conditions = {})
      results = []
      query(conditions.merge(:band => "AM")) do |feed|
        feed.each_line do |row|
          fields = row.split("|").select { |field| (field.strip! && !field.nil?)}
          results << Station.new(*fields)
        end
      end
      # if call letters are supplied, return matches that match call letters exactly.
      # FCC does partial matches (from the start of the string), so that "KUT" will return "KUTT", also
      if conditions[:call_letters]
        exact_matches =  results.select { |d| d.call_letters == conditions[:call_letters] }
        results = exact_matches if (exact_matches)
      end

      #sort by signal strength
      if results.size > 1
        results.sort_by { |s| s.signal_strength}.reverse
      else
        results
      end
    end

    private

    def self.query(conditions = {})
      query = ""
      prepare_args(conditions).each { |k,v| query += "#{k}=#{v}&" }
      url = "#{BASE_URL}?#{query}"
      feed = open(url)
      yield feed
    end

    def self.prepare_args(params)
      return {
        :state => params[:state],
        :call => params[:call_letters],
        :city => params[:city],
        :arn => nil,
        :serv => params[:band],
        :vac => nil,
        :freq => params[:frequency] || params[:frequency_lower] || "530",
        :fre2 => params[:frequency] || params[:frequency_upper] || "1700",
        :facid => nil,
        :class => nil,
        :dkt => nil,
        :dist => nil,
        :dlat2 => nil,
        :dlon2 => nil,
        :mlon2 => nil,
        :mlat2 => nil,
        :slat2 => nil,
        :slon2 => nil,
        # :NS => "N",
        # :e => 9,
        :EW => "W",
        :list => 4, # pipe separated output
        :size => 9
       }
    end

  end
end