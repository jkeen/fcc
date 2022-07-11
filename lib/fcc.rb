# frozen_string_literal: true
require_relative './fcc/station'
require_relative './fcc/station/cache'
require_relative './fcc/station/info'
require_relative './fcc/station/extended_info'
require_relative './fcc/station/record_delegate'

module FCC
  FM_FULL_SERVICE = 'FM'
  FM_LOW_POWER = 'FL'
  FM_BOOSTER = 'FB'
  FM_TRANSLATOR = 'FX'

  def self.cache
    @cache ||= Station::Cache.new
  end

  def self.cache=(cache_service)
    @cache = cache_service
  end

  def self.log(message)
    @logger ||= Logger.new($stdout)
    @logger.info(message)
  end

  def self.error(message)
    @error_logger ||= Logger.new($stderr)
    @error_logger.error(message)
  end
end