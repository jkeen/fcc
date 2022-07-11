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
        @facilities ||= CSV.parse(File.read(lms_file(:facility)), col_sep: '|', headers: true)
      end

      def common_station_data
        @common_station_data ||= CSV.parse(File.read(lms_file(:common_station)), col_sep: '|', headers: true)
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

      protected

      def call_signs_match?(ours, theirs)
        theirs.to_s.upcase.to_s == ours.to_s.upcase.to_s || theirs.to_s.upcase =~ Regexp.new("^#{ours.to_s.upcase}[-—–][A-Z0-9]+$")
      end

      def lms_file(file_name)
        remote_url = URI("#{BASE_URI}/#{lms_date}/#{file_name}.zip")
        # FCC.cache.fetch "#{lms_date}-#{file_name}-cache" do

        base_file_name = File.join(FCC::TMP_DIR, "#{lms_date}-#{file_name}")
        zip_file = "#{base_file_name}.zip"
        dat_file = "#{base_file_name}.dat"

        unless File.exist?(zip_file)
          response = nil
          http_download_uri(remote_url, zip_file)
        end

        unless File.exist?(dat_file)
          paths = []
          Zip::File.open(zip_file) do |zip_file|
            zip_file.each do |f|
              FileUtils.mkdir_p(File.dirname(dat_file))
              zip_file.extract(f, dat_file)

              break
            end
          end
        end

        dat_file
        # end
      end

      def http_download_uri(uri, filename)
        puts 'Downloading ' + uri.to_s
        http_object = Net::HTTP.new(uri.host, uri.port)
        http_object.use_ssl = true if uri.scheme == 'https'
        begin
          http_object.start do |http|
            request = Net::HTTP::Get.new uri.request_uri
            http.read_timeout = 500
            http.request request do |response|
              open(filename, 'w') do |io|
                response.read_body do |chunk|
                  io.write chunk
                end
              end
            end
          end
        rescue Exception => e
          puts "=> Exception: '#{e}'. Skipping download."
          return
        end
        puts 'Stored download as ' + filename + '.'

        filename
      end

      def lms_date
        Date.today.strftime('%m-%d-%Y')
      end
    end
  end
end
