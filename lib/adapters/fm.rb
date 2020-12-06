#TODO turn these into Faraday adapters?      

module FCC
  module Adapters
    module FM
      def discard_result?(fields)
              # results = results.select(&:good?)
        # if call letters are supplied, return matches that match call letters exactly.
        attrs = parse_results(fields)

        return true if attrs[:call_letters] == 'NEW'
        return true if attrs[:call_letters] == '-'
        return true if attrs[:band] != 'FM'
      end

      def build_query(params)
        if params[:frequency].is_a?(Range)
          lower_frequency = params[:frequency].first
          upper_frequency = params[:frequency].last
        else
          lower_frequency = params[:frequency] || params[:frequency_lower] || '87.1'
          upper_frequency = params[:frequency] || params[:frequency_upper] || '108.0'
        end

        {
          state: params[:state],
          call: params[:call_letters]&.upcase,
          city: params[:city],
          arn: nil,
          serv: params[:band],
          vac: 3, # licensed records only
          freq: lower_frequency,
          fre2: upper_frequency,
          facid: params[:fcc_id],
          class: nil,
          dkt:   nil,
          dist:  nil,
          dlat2: nil,
          dlon2: nil,
          mlon2: nil,
          mlat2: nil,
          slat2: nil,
          slon2: nil,
          # NS: "N",
          # e: 9,
          EW: 'W',
          list: 4, # pipe separated output
          size: 9
        }
      end

      def parse_results(fields)
        {}.tap do |attrs|
          attrs[:call_letters]    = fields[0]
          attrs[:frequency]       = parse_frequency(fields[1])
          attrs[:band]            = fields[2]
          attrs[:channel]         = fields[3]
          # fields[4] # Directional Antenna (DA) or NonDirectional (ND)
          # fields[5] # (Not Used for FM)
          attrs[:station_class]   = fields[6]
          # fields[7] # (Not Used for FM)
          attrs[:status]          = fields[8]
          attrs[:city]            = fields[9]
          attrs[:state]           = fields[10]
          attrs[:country]         = fields[11]
          attrs[:file_number]     = fields[12]  #File Number (Application, Construction Permit or License) or
          attrs[:signal_strength] = parse_signal_strength(fields[13]) # Effective Radiated Power --
          # fields[14] # Effective Radiated Power -- vertically polarized (maximum)
          # fields[15] # Antenna Height Above Average Terrain (HAAT) -- horizontal polarization
          # fields[16] # Antenna Height Above Average Terrain (HAAT) -- vertical polarization
          attrs[:fcc_id]          = fields[17] # Facility ID Number (unique to each station)
          attrs[:latitude]        = parse_latitude(fields[18], fields[19], fields[20], fields[21])
          attrs[:longitude]       = parse_longitude(fields[22], fields[23], fields[24], fields[25])
          attrs[:licensed_to]     = fields[26] # Licensee or Permittee
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
      end

      private

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
  end
end