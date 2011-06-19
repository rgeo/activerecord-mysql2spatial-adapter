::Gem::Specification.new do |s_|
  s_.name = 'activerecord-mysql2spatial-adapter'
  s_.summary = 'An ActiveRecord adapter for MySQL Spatial Extensions, based on RGeo and the mysql2 gem.'
  s_.description = "This is an ActiveRecord connection adapter for MySQL Spatial Extensions. It is based on the stock MySQL2 adapter, but provides built-in support for spatial columns. It uses the RGeo library to represent spatial data in Ruby."
  s_.version = "#{::File.read('Version').strip}.build#{::Time.now.utc.strftime('%Y%m%d%H%M%S')}"
  s_.author = 'Daniel Azuma'
  s_.email = 'dazuma@gmail.com'
  s_.homepage = "http://virtuoso.rubyforge.org/activerecord-mysql2spatial-adapter"
  s_.rubyforge_project = 'virtuoso'
  s_.required_ruby_version = '>= 1.8.7'
  s_.files = ::Dir.glob("lib/**/*.rb") +
    ::Dir.glob("test/**/*.rb") +
    ::Dir.glob("*.rdoc") +
    ['Version']
  s_.extra_rdoc_files = ::Dir.glob("*.rdoc")
  s_.test_files = ::Dir.glob("test/**/tc_*.rb")
  s_.platform = ::Gem::Platform::RUBY
  s_.add_dependency('rgeo-activerecord', '~> 0.3.4')
  s_.add_dependency('mysql2', '>= 0.2.6')
end
