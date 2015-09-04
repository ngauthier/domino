# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name = "domino"
  gem.version = "0.7.1"
  gem.platform = Gem::Platform::RUBY
  gem.authors = ["Nick Gauthier"]
  gem.email = ["ngauthier@gmail.com"]
  gem.homepage = "http://github.com/ngauthier/domino"
  gem.summary = "View abstraction for integration testing"
  gem.description = %{
    Make it easier to deal with UI elements by providing an
    interface that decouples your tests from your views.
  }
  gem.rubygems_version = '>= 1.3.6'
  gem.files = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.extra_rdoc_files = ['README.md']
  gem.license = 'MIT'

  gem.add_dependency('capybara', '>= 0.4.0')
  gem.add_development_dependency('minitest')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('simplecov')
end

