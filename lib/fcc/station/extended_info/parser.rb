require 'httparty'

module FCC
  module Station
    class ExtendedInfoParser < HTTParty::Parser
      def parse
        results = []
        body.each_line do |row|
          attrs = {}
          attrs[:raw] = row
          fields = row.split('|').slice(1...-1).collect(&:strip).map { |v| v == '-' ? "" : v }

          attrs[:call_sign]                = fields[0]
          attrs[:frequency]                = parse_frequency(fields[1])
          attrs[:band]                     = fields[2]
          attrs[:channel]                  = fields[3]
          attrs[:antenna_type]             = fields[4] # Directional Antenna (DA) or NonDirectional (ND)
          attrs[:am_operating_time]        = fields[5] if fields[5] && attrs[:band] == "AM" # (Only used for AM)
          attrs[:station_class]            = fields[6]
          attrs[:region_2_station_class]   = fields[7] if fields[7] && attrs[:band] == "AM" # (only used for AM)
          attrs[:status]                   = fields[8]
          attrs[:city]                     = fields[9]
          attrs[:state]                    = fields[10]
          attrs[:country]                  = fields[11]
          attrs[:file_number]              = fields[12]  #File Number (Application, Construction Permit or License) or
          attrs[:signal_strength]          = parse_signal_strength(fields[13]) # Effective Radiated Power --
          attrs[:effective_radiated_power] = parse_signal_strength(fields[14]) # Effective Radiated Power -- vertically polarized (maximum)
          attrs[:haat_horizontal]          = fields[15] # Antenna Height Above Average Terrain (HAAT) -- horizontal polarization
          attrs[:haat_vertical]            = fields[16] # Antenna Height Above Average Terrain (HAAT) -- vertical polarization
          attrs[:fcc_id]                   = fields[17] # Facility ID Number (unique to each station)
          attrs[:latitude]                 = parse_latitude(fields[18], fields[19], fields[20], fields[21])
          attrs[:longitude]                = parse_longitude(fields[22], fields[23], fields[24], fields[25])
          attrs[:licensed_to]              = fields[26] # Licensee or Permittee

          results << attrs
        end

        results
      end

      def parse_longitude(direction, degrees, minutes, seconds)
        decimal_degrees = degrees.to_i + (minutes.to_f / 60) + (seconds.to_f / 3600)

        "#{direction =~ /W/ ? '-' : ''}#{decimal_degrees}"
      end

      def parse_latitude(direction, degrees, minutes, seconds)
        decimal_degrees = degrees.to_i + (minutes.to_f / 60) + (seconds.to_f / 3600)

        "#{direction =~ /S/ ? '-' : ''}#{decimal_degrees}"
      end

      def parse_signal_strength(raw_signal)
        if raw_signal
          parsed_signal = raw_signal[/[0-9]+\.?[0-9]?/]
          "#{parsed_signal.to_f} #{raw_signal.scan(/\w+$/).first}"
        end
      end

      def parse_frequency(freq)
        freq.to_f
      end
    end
  end
end