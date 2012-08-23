Gem::Specification.new do |s|
  s.name = "domino"
  s.version = "0.2.1"
  s.platform = Gem::Platform::RUBY
  s.author = "Nick Gauthier"
  s.email = "ngauthier@gmail.com"
  s.homepage = "http://www.github.com/ngauthier/domino"
  s.summary = "View abstraction for integration testing"
  s.description = %{
    Make it easier to deal with UI elements by providing an
    interface that decouples your tests from your views.
  }
  s.rubygems_version = '>= 1.3.6'
  s.files = [
    'lib/domino.rb',
    'MIT-LICENSE',
    'README.md'
  ]
  s.extra_rdoc_files = ['README.md']
  s.license = 'MIT'
  s.add_dependency('capybara', '>= 0.4.0')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rake')
  s.add_development_dependency('simplecov')
end

