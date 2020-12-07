require 'fcc'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
  end
end