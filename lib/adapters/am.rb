#TODO turn these into Faraday adapters?      
module FCC
  module Adapters
    module AM
      def discard_result?(fields)
        false
      end

      def build_query(params)
        {
          state: params[:state],
          call: params[:call_letters],
          city: params[:city],
          arn: nil,
          serv: params[:band],
          vac: nil,
          freq: params[:frequency] || params[:frequency_lower] || '530',
          fre2: params[:frequency] || params[:frequency_upper] || '1700',
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

      def parse_results(fields)
        {}.tap do |attrs|
          attrs[:call_letters]        = fields[0]
          attrs[:frequency]           = fields[1]
          attrs[:band]                = fields[2]
          #                             fields[3]  # Not used for AM
          #                             fields[4]  # Directional Antenna (DA) or NonDirectional (ND)
          attrs[:hours]               = fields[5]  # Hours of operation for this record (daytime, nighttime, or unlimited)
          attrs[:domestic_class]      = fields[6]  # Domestic US Station class
          attrs[:international_class] = fields[7] # International station class
          attrs[:fm_status]           = fields[8]
          attrs[:city]                = fields[9]
          attrs[:state]               = fields[10]
          attrs[:country]             = fields[11]
          attrs[:file_number]         = fields[12] # File Number (Application, Construction Permit or License) or Docket Number (Rulemaking)
          attrs[:signal_strength]     = fields[13] # Power
          #                             fields[14] # Not used
          #                             fields[15] # Not used
          #                             fields[16] # Not used
          attrs[:fcc_id]              = fields[17] # Facility ID Number (unique to each station)
          attrs[:latitude]            = parse_latitude(fields[18], fields[19], fields[20], fields[21])
          attrs[:longitude]           = parse_longitude(fields[22], fields[23], fields[24], fields[25])
          attrs[:licensed_to]         = fields[26] # Licensee or Permittee
          #                             fields[27] # Kilometers distant (radius) from entered latitude, longitude
          #                             fields[28] # Miles distant (radius) from entered latitude, longitude
          #                             fields[29] # Azimuth, looking from center Lat, Lon to this record's Lat, Lon
          #                             fields[30] # Application ID number (from CDBS database)***
        end
      end

      private

      def parse_longitude(direction, degrees, minutes, _seconds)
        "#{(direction =~ /W/ ? '-' : '')}#{degrees}.#{minutes}"
      end

      def parse_latitude(direction, degrees, minutes, _seconds)
        "#{(direction =~ /S/ ? '-' : '')}#{degrees}.#{minutes}"
      end
    end
  end
end