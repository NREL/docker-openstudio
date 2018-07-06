require 'rubygems'

def local_gems
   Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.group_by{ |g| g.name }
end

puts local_gems.map{ |name, specs| 
  [ 
    name,
    specs.map{ |spec| spec.version.to_s }.join(',')
  ].join(' ') 
}

require 'openstudio'
require 'openstudio-standards'
puts OpenstudioStandards::VERSION
raise "OpenStudio Standards version does not match" unless OpenstudioStandards::VERSION == '0.1.14.pre.ambient'
