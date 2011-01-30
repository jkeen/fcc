require 'open-uri'

module FCC
  class FM
    class Station
      attr_reader :raw, :call_letters, :band, :channel, :fm_status, :file_number, :station_class, :fcc_id, :city, :state, :country, :licensed_to
      def initialize(*fields)
        @raw =                fields
        @call_letters =       fields[0]  # Call Letters
        @frequency =          fields[1]  # Frequency
        @band =               fields[2]  # Service
        @channel =            fields[3]  # Channel
        #                     fields[4]  # Directional Antenna (DA) or NonDirectional (ND)
        #                     fields[5]  # (Not Used for FM)
        @station_class =      fields[6]  # FM Station Class
        #                     fields[7]  # (Not Used for FM)
        @fm_status =          fields[8]  # FM Status
        @city =               fields[9]  # City
        @state =              fields[10] # State
        @country =            fields[11] # Country
        @file_number =        fields[12] # File Number (Application, Construction Permit or License) or Docket Number (Rulemaking)
        @signal_strength =    fields[13]
        #                     fields[13] # Effective Radiated Power -- horizontally polarized  (maximum)
        #                     fields[14] # Effective Radiated Power -- vertically polarized  (maximum)
        #                     fields[15] # Antenna Height Above Average Terrain (HAAT) -- horizontal polarization
        #                     fields[16] # Antenna Height Above Average Terrain (HAAT) -- vertical polarization
        @fcc_id =             fields[17] # Facility ID Number (unique to each station)

        @latitude_direction = fields[18] # N (North) or S (South) Latitude
        @latitude_degrees =   fields[19] # Degrees Latitude
        @latitude_minutes =   fields[20] # Minutes Latitude
        @latitude_seconds =   fields[21] # Seconds Latitude
        @longitude_direction =fields[22] # W (West) or (E) East Longitude
        @longitude_degrees =  fields[23] # Degrees Longitude
        @longitude_minutes =  fields[24] # Minutes Longitude
        @longitude_seconds =  fields[25] # Seconds Longitude
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

      def longitude
        "#{(@longitude_direction =~ /S/ ? "-" : "")}#{@longitude_degrees}.#{@longitude_minutes}"
      end

      def latitude
        "#{(@latitude_direction =~ /S/ ? "-" : "")}#{@latitude_degrees}.#{@latitude_minutes}"
      end

      def signal_strength
        @signal_strength.gsub(/\.\s+/, ".0 ") if @signal_strength
      end

      def frequency
        @frequency[/[0-9]+\.?[0-9]/] if @frequency
      end

      def good?
        !["NEW", "-"].include?(@call_letters) && @call_letters =~ /^[^0-9]/ && @band == "FM"
      end
    end

    BASE_URL = "http://www.fcc.gov/fcc-bin/fmq"

    def self.find(call_letters)
      raise ArgumentError, "no call letters were supplied" if call_letters.nil? || call_letters.strip.length == 0

      find_all(:call_letters => call_letters).first
    end

    def self.find_all(conditions = {})
      results = []
      query(conditions) do |feed|
        feed.each_line do |row|
          fields = row.split("|").select { |field| (field.strip! && !field.nil?)}
          results << Station.new(*fields)
          puts results.inspect
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

      #sort by signal strength
      if results.size > 1
        results.sort_by { |s| s.signal_strength}.reverse
      else
        results
      end
    end

    private

    def self.query(conditions = {})
      # list=3 => parameter in the parameter string produced a text only display with pipes separating fields
      # serv=FM => commerical FM stations
      conditions.merge!({:band => "FM"})

      query = ""
      prepare_args(conditions).each { |k,v| query += "#{k}=#{v}&" }
      url = "#{BASE_URL}?#{query}"
      feed = open(url)

      yield feed
    end

    def self.prepare_args(params)
      if params[:frequency]
        params[:frequency_lower] = params[:frequency]
        params[:frequency_upper] = params[:frequency]
      else
        params[:frequency_lower] = "0.0"
        params[:frequency_upper] = "108.0"
      end

      return {
        :state => params[:state],
        :call => params[:call_letters],
        :city => params[:city],
        :arn => nil,
        :serv => params[:band],
        :vac => nil,
        :freq => params[:frequency_lower],
        :fre2 => params[:frequency_upper],
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
        :list => 4,
        :size => 9
       }
    end

  end
end