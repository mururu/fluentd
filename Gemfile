source 'https://rubygems.org/'

gemspec

gem 'msgpack', github: 'msgpack/msgpack-ruby'
gem 'strptime', github: 'mururu/strptime', branch: 'raise-for-unspported-format'

local_gemfile = File.join(File.dirname(__FILE__), "Gemfile.local")
if File.exist?(local_gemfile)
  puts "Loading Gemfile.local ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(local_gemfile)
end
