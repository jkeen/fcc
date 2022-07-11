require 'httparty'
require 'open-uri'
require 'net/http'
require 'uri'
require 'date'
require_relative './parsers/lms_data'

module FCC
  module Station
    class LmsData
      BASE_URI = 'https://enterpriseefiling.fcc.gov/dataentry/api/download/dbfile'
      # include HTTParty

      def find_all_related(call_sign: )
        stations = find_related_stations(call_sign: call_sign)
        translators = find_translators_for(call_sign: stations.keys)
        stations.merge(translators)
      end

      def find_translators_for(call_sign: )
        call_signs = [call_sign].flatten

        records = common_station_data.entries.select do |entry|
          call_signs.any? { |call_sign| call_signs_match?(call_sign, entry['callsign']) }
        end 

        facility_ids = records.map { |r| r['facility_id'] }.uniq.compact

        matched_facilities = facilities.entries.select do |facility|
          facility_ids.include?(facility['primary_station']) #{}|| facility_ids.include?(facility['facility_id'])
        end

        {}.tap do |hash|
          matched_facilities.each do |record|
            hash[record['callsign']] = record['facility_id']
          end
        end
      end

      def find_related_stations(call_sign: )
        call_signs = [call_sign].flatten

        records = common_station_data.entries.select do |entry|
          call_signs.any? { call_signs_match?(call_sign, entry['callsign']) }
        end

        correlated_app_ids = records.map { |m| m['eeo_application_id'] }
        matches = common_station_data.entries.select do |entry|
          correlated_app_ids.include?(entry['eeo_application_id'])
        end

        {}.tap do |hash|
          matches.each do |record|
            hash[record['callsign']] = record['facility_id']
          end
        end
      end

      def facilities
        @facilities ||= read(:facility)
      end

      def common_station_data
        @common_station_data ||= read(:common_station)
      end

      def find_facilities(facility_ids:, call_signs: [])
        matched_facilities = facilities.entries.select do |facility|
          facility_ids.include?(facility['primary_station']) || facility_ids.include?(facility['facility_id']) || call_signs.include?(facility['callsign'])
        end

        {}.tap do |hash|
          matched_facilities.each do |record|
            hash[record['callsign']] = record['facility_id']
          end
        end
      end

      def find_call_signs(call_signs:)
        common_station_data.entries.select do |entry|
          call_signs.any? do |call_sign|
            call_signs_match?(call_sign, entry['callsign'])
          end
        end
      end

      def read(file_name)
        key = "#{lms_date}-#{file_name}"
        remote_url = URI("#{BASE_URI}/#{lms_date}/#{file_name}.zip")
        FCC.log remote_url
        contents = FCC.cache.fetch key do
          begin
            temp_file = http_download_uri(remote_url)
            break if temp_file.empty?

            contents = ""
            Zip::File.open_buffer(temp_file) do |zf| 
              contents = zf.read(zf.entries.first)
              break
            end

            value = contents
          rescue Exception => e
            FCC.error(e.message)
            value = nil
          ensure
            value
          end
        end

        if contents
          CSV.parse(contents, col_sep: '|', headers: true)
        end
      end

      protected

      def call_signs_match?(ours, theirs)
        theirs.to_s.upcase.to_s == ours.to_s.upcase.to_s || theirs.to_s.upcase =~ Regexp.new("^#{ours.to_s.upcase}[-—–][A-Z0-9]+$")
      end

      def http_download_uri(uri)
        FCC.log 'Downloading ' + uri.to_s
        begin
          Tempfile.create { HTTParty.get(uri)&.body }
        rescue Exception => e
          FCC.error "=> Exception: '#{e}'. Skipping download."

          raise e
          return false
        end
      end

      def lms_date
        Date.today.strftime('%m-%d-%Y')
      end
    end
  end
end
