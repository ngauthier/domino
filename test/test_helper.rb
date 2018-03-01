require 'bundler/setup'
unless ENV['CI']
  require 'simplecov'
  SimpleCov.start
end
Bundler.require
require 'minitest/autorun'
require 'minitest/mock'
