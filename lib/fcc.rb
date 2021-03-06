# frozen_string_literal: true
require_relative './fcc/station'
require_relative './fcc/station/cache'
require_relative './fcc/station/info'
require_relative './fcc/station/extended_info'
require_relative './fcc/station/result_delegate'

module FCC
  def self.cache
    @cache ||= Station::Cache.new
  end

  def self.cache=(cache_service)
    @cache = cache_service
  end
end