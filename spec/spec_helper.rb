$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'solrizer/fedora'
require 'solrizer'
require 'rspec'


# this allows us to unload constants for testing
module Kernel
  # Suppresses warnings within a given block.
  def with_warnings_suppressed
    saved_verbosity = $-v
    $-v = nil
    yield
  ensure
    $-v = saved_verbosity
  end
end


RSpec.configure do |config|
  
  config.mock_with :mocha
  config.color_enabled = true
  
  def fixture(file)
    File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
  end
  
end
