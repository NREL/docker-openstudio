require 'openstudio'
require 'rubygems'
require 'fileutils'

# Make sure we can load FFI as it is a very nice dependency
begin
  gem 'ffi'
rescue LoadError
  system('gem install ffi')
  system('gem install semantic')
  Gem.clear_paths
end

# After installation, then it should be able to require ffi
require 'ffi'

# Install semantic to support checking versions easily.
require 'semantic'
require 'semantic/core_ext'

puts "OpenStudio Version: #{OpenStudio.openStudioLongVersion}"

# Should be able to require openstudio-standards, this is ignored for now.
# require 'openstudio-standards'
# standard = Standard.build("90.1-2004_SmallOffice")
# puts standard

# Make sure I can write out an example model
puts OpenStudio::Model.exampleModel.to_s

# Grab the test files that are shipped with OpenStudio and put into a folder and run
FileUtils.rm_rf 'test/compact_osw'
if OpenStudio.openStudioVersion.to_version > '2.5.1'.to_version
  FileUtils.cp_r "/usr/local/openstudio-#{OpenStudio.openStudioVersion}/Examples/compact_osw", 'test/.'
  `/usr/local/bin/openstudio run -w test/compact_osw/compact.osw`
else 
  FileUtils.cp_r "/usr/Examples/compact_osw", 'test/.'
  `/usr/bin/openstudio run -w test/compact_osw/compact.osw`
end
raise "Simulation did not run" unless File.exist?('test/compact_osw/run/finished.job')
