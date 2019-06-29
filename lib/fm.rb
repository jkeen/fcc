# frozen_string_literal: true

require 'open-uri'

module FCC
  class FM
    class Station
      attr_accessor :response, :frequency, :call_letters, :band, :channel, :fm_status, :latitude, :longitude, :file_number, :station_class, :fcc_id, :city, :state, :country, :licensed_to, :signal_strength

      def initialize(*fields)
        # :call_letters,
        # :frequency,
        # :band,
        # :channel,
        # :antenna_type => "Direction Antenna (DA) or NonDirectional (ND)"
        # :ignore => "Not used for FM"
        # :station_class,
        # :ignore,
        # :fm_status,
        # :city,
        # :state,
        # :country,
        # :file_number => "File Number (Application, Construction Permit or License) or Docket Number (Rulemaking)"
        # :signal_strength => "Effective Radiated Power -- horizontally polarized  (maximum)"
        # :ignore,
        # :ignore,
        # :ignore,
        # :fcc_id => "Facility ID number (unique to each station)",

        @response        = fields
        @call_letters    = fields[0]
        @frequency       = parse_frequency(fields[1])
        @band            = fields[2]
        @channel         = fields[3]
        # fields[4] # Directional Antenna (DA) or NonDirectional (ND)
        # fields[5] # (Not Used for FM)
        @station_class   = fields[6]
        # fields[7] # (Not Used for FM)
        @fm_status       = fields[8]
        @city            = fields[9]
        @state           = fields[10]
        @country         = fields[11]
        @file_number     = fields[12] # File Number (Application, Construction Permit or License) or Docket Number (Rulemaking)
        @signal_strength = parse_signal_strength(fields[13]) # Effective Radiated Power -- horizontally polarized (maximum)
        # fields[14] # Effective Radiated Power -- vertically polarized (maximum)
        # fields[15] # Antenna Height Above Average Terrain (HAAT) -- horizontal polarization
        # fields[16] # Antenna Height Above Average Terrain (HAAT) -- vertical polarization
        @fcc_id          = fields[17] # Facility ID Number (unique to each station)

        @latitude        = parse_latitude(fields[18], fields[19], fields[20], fields[21])
        @longitude       = parse_longitude(fields[22], fields[23], fields[24], fields[25])

        @licensed_to     = fields[26] # Licensee or Permittee
        # fields[27] # Kilometers distant (radius) from entered latitude, longitude
        # fields[28] # Miles distant (radius) from entered latitude, longitude
        # fields[29] # Azimuth, looking from center Lat, Lon to this record's Lat, Lon
        # fields[30] # Antenna Radiation Center Above Mean Sea Level (RCAMSL) - Horizontally Polarized - meters
        # fields[31] # Antenna Radiation Center Above Mean Sea Level (RCAMSL) - Vertically Polarized - meters
        # fields[32] # Directional Antenna ID Number
        # fields[33] # Directional Antenna Pattern Rotation (degrees)
        # fields[34] # Antenna Structure Registration Number
        # fields[35] # Application ID number (from CDBS database)***
      end

      def to_json(*_args)
        json = {}
        output_attributes.collect do |attr|
          json[attr.to_s] = send(attr)
        end

        json
      end

      def inspect
        lines = []
        lines << %(#{call_letters} #{frequency}#{band})
        lines << %(#{city} #{state} #{country})
        lines << fcc_id.to_s
        lines.join("\n")
      end

      def good?
        return false if call_letters == 'NEW'
        return false if call_letters == '-'
        return false if band != 'FM'

        # @call_letters =~ /^[^0-9]/

        true
      end

      private

      def output_attributes
        %i[frequency call_letters band channel fm_status latitude longitude file_number station_class fcc_id city state country licensed_to signal_strength]
      end

      def parse_longitude(direction, degrees, minutes, _seconds)
        "#{(direction =~ /W/ ? '-' : '')}#{degrees}.#{minutes}"
      end

      def parse_latitude(direction, degrees, minutes, _seconds)
        "#{(direction =~ /S/ ? '-' : '')}#{degrees}.#{minutes}"
      end

      def parse_signal_strength(raw_signal)
        signal = raw_signal&.gsub(/\.\s+/, '.0 ')
        signal.gsub(/\s+/, ' ')
      end

      def parse_frequency(freq)
        freq[/[0-9]+\.?[0-9]/] if freq
      end
    end

    BASE_URL = 'http://www.fcc.gov/fcc-bin/fmq'

    def self.find(call_letters)
      raise ArgumentError, 'no call letters were supplied' if call_letters.nil? || call_letters.strip.empty?

      find_all(call_letters: call_letters).first
    end

    def self.find_all(conditions = {})
      results = []
      query(conditions.merge(band: 'FM')) do |feed|
        feed.each_line do |row|
          fields = row.split('|').select do |field|
            (field.strip! && !field.nil?)
          end
          
          results << Station.new(*fields)
        end
      end
      # remove invalid values, such as "NEW", or "-", stations starting with numbers, and non-FM bands
      # results = results.select(&:good?)
      # if call letters are supplied, return matches that match call letters exactly.
      # FCC does a starts_with search, so that "KUT" will return "KUTT", also

      if conditions[:call_letters]
        exact_matches = results.select do |d|
          d.call_letters.downcase == conditions[:call_letters].downcase
        end

        results = exact_matches if exact_matches
      end

      # sort by signal strength
      if results.size > 1
        results.sort_by(&:signal_strength).reverse
      else
        results
      end
    end

    private

    def self.query(conditions = {})
      query = ''
      prepare_args(conditions).each { |k, v| query += "#{k}=#{v}&" }
      url = "#{BASE_URL}?#{query}"
      puts url
      feed = open(url)
      yield feed
    end

    def self.prepare_args(params)
      {
        state: params[:state],
        call: params[:call_letters],
        city: params[:city],
        arn: nil,
        serv: params[:band],
        vac: 3, # licensed records only
        freq: params[:frequency] || params[:frequency_lower] || '0.0',
        fre2: params[:frequency] || params[:frequency_upper] || '108.0',
        facid: params[:fcc_id],
        class: nil,
        dkt: nil,
        dist: nil,
        dlat2: nil,
        dlon2: nil,
        mlon2: nil,
        mlat2: nil,
        slat2: nil,
        slon2: nil,
        # :NS => "N",
        # :e => 9,
        EW: 'W',
        list: 4, # pipe separated output
        size: 9
      }
    end
  end
end
