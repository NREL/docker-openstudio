#!/usr/bin/env bash

rm -rf mygems
rm -f Gemfile.lock
bundle install --path mygems
openstudio --verbose --bundle Gemfile --bundle_path mygems test_gemfile.rb

rm -rf mygems
rm -f Gemfile-git.lock
bundle install --gemfile=Gemfile-git --path mygems
openstudio --verbose --bundle Gemfile-git --bundle_path mygems test_gemfile_git.rb

# rm -rf mygems
# rm -f Gemfile-native.lock
# bundle install --gemfile=Gemfile-native
# openstudio --gem_path mygems/ruby/2.2.0 --gem_path mygems/ruby/2.2.0/bundler/gems execute_ruby_script test_gemfile_native.rb
