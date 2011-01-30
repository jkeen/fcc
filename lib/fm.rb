require 'open-uri'

module FCC
  class FM
    class Station
      attr_reader :call_letters, :band, :channel, :fm_status, :latitude, :longitude, :file_number, :station_class, :fcc_id, :city, :state, :country, :licensed_to
      def initialize(*fields)
        @raw =                fields
        @call_letters =       fields[0]
        @frequency =          frequency(fields[1])
        @band =               fields[2]
        @channel =            fields[3]
        #                     fields[4]  # Directional Antenna (DA) or NonDirectional (ND)
        #                     fields[5]  # (Not Used for FM)
        @station_class =      fields[6]
        #                     fields[7]  # (Not Used for FM)
        @fm_status =          fields[8]
        @city =               fields[9]
        @state =              fields[10]
        @country =            fields[11]
        @file_number =        fields[12] # File Number (Application, Construction Permit or License) or Docket Number (Rulemaking)
        @signal_strength =    signal_strength(fields[13]) # Effective Radiated Power -- horizontally polarized  (maximum)
        #                     fields[14] # Effective Radiated Power -- vertically polarized  (maximum)
        #                     fields[15] # Antenna Height Above Average Terrain (HAAT) -- horizontal polarization
        #                     fields[16] # Antenna Height Above Average Terrain (HAAT) -- vertical polarization
        @fcc_id =             fields[17] # Facility ID Number (unique to each station)

        @latitude =           latitude(fields[18], fields[19], fields[20], fields[21])
        @longitude =          longitude(fields[22], fields[23], fields[24], fields[25])

        @licensed_to =        fields[26] # Licensee or Permittee
        #                     fields[27] # Kilometers distant (radius) from entered latitude, longitude
        #                     fields[28] # Miles distant (radius) from entered latitude, longitude
        #                     fields[29] # Azimuth, looking from center Lat, Lon to this record's Lat, Lon
        #                     fields[30] # Antenna Radiation Center Above Mean Sea Level (RCAMSL) - Horizontally Polarized - meters
        #                     fields[31] # Antenna Radiation Center Above Mean Sea Level (RCAMSL) - Vertically Polarized - meters
        #                     fields[32] # Directional Antenna ID Number
        #                     fields[33] # Directional Antenna Pattern Rotation (degrees)
        #                     fields[34] # Antenna Structure Registration Number
        #                     fields[35] # Application ID number (from CDBS database)***
      end

      def good?
        return false if @call_letters == "NEW"
        return false if @call_letters == "-"
        return false if @band != "FM"
        #@call_letters =~ /^[^0-9]/

        true
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

    BASE_URL = "http://www.fcc.gov/fcc-bin/fmq"

    def self.find(call_letters)
      raise ArgumentError, "no call letters were supplied" if call_letters.nil? || call_letters.strip.length == 0

      find_all(:call_letters => call_letters).first
    end

    def self.find_all(conditions = {})
      results = []
      query(conditions.merge(:band => "FM")) do |feed|
        feed.each_line do |row|
          fields = row.split("|").select { |field| (field.strip! && !field.nil?)}
          results << Station.new(*fields)
        end
      end
      #remove invalid values, such as "NEW", or "-", stations starting with numbers, and non-FM bands
      results = results.select(&:good?)
      # if call letters are supplied, return matches that match call letters exactly.
      # FCC does a starts_with search, so that "KUT" will return "KUTT", also
      if conditions[:call_letters]
        exact_matches =  results.select { |d| d.call_letters == conditions[:call_letters] }
        results = exact_matches if (exact_matches)
      end

      results
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
        :freq => params[:frequency] || params[:frequency_lower] || "0.0",
        :fre2 => params[:frequency] || params[:frequency_upper] || "108.0",
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