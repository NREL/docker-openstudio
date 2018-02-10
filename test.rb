require 'openstudio'
require 'rubygems'

# Make sure we can load FFI as it is a very nice dependency
begin
  gem 'ffi'
rescue LoadError
  system('gem install ffi')
  Gem.clear_paths
end

require 'ffi'

puts OpenStudio::Model.exampleModel.to_s