require 'bundler/gem_tasks'

desc "Run the tests"
task :test do
  require File.join(File.dirname(__FILE__), 'test', 'test_helper.rb')
  Dir[File.join(File.dirname(__FILE__), "test", "**", "*.rb")].each { |f| require f }
end

task :default => :test
