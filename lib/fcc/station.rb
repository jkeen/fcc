require 'active_support/core_ext/module/delegation'
require_relative 'station/extended_info'
require_relative 'station/cache'
require_relative 'station/index'
require_relative 'station/info'
require_relative 'station/result'
require_relative 'station/lms_data'
require_relative 'station/record_group'
require_relative 'station/record_delegate'

module FCC
  module Station
    Contact = Struct.new(:name, :title, :address, :address2, :city, :state, :country, :zip_code, :phone, :fax, :email, :website, keyword_init: true)
    Community = Struct.new(:city, :state, :country, keyword_init: true)

    def self.find_each(service, &block)
      results = index(service).results

      results.each do |result|
        yield find(service, result['callSign'])
      end
    end

    def self.find(service, call_sign, options = {})
      Result.new(service, call_sign, options)
    end

    def self.index(service)
      case service.to_s.downcase.to_sym
      when :fm
        @fm_index ||= Index.new(:fm)
      when :am
        @am_index ||= Index.new(:am)
      when :tv
        @tv_index ||= Index.new(:tv)
      else
        raise "unsupported service #{service}. :fm, :am, and :tv are valid"
      end
    end

    def self.extended_info_cache
      @cache ||= Station::Cache.new
    end
  end
end