#!/usr/bin/env bash

bundle install --path mygems
openstudio --gem_path mygems/ruby/2.2.0 --gem_path mygems/ruby/2.2.0/bundler/gems execute_ruby_script test_gemfile.rb