require "bundler/gem_tasks"
require "rake/extensiontask"
require 'rubygems/package_task'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$gemspec = Bundler::GemHelper.gemspec

Gem::PackageTask.new($gemspec) do |pkg|
end

Rake::ExtensionTask.new "h8", $gemspec do |ext|
  ext.lib_dir        = "lib/h8"
  ext.source_pattern = "*.{c,cpp,js}"
  ext.gem_spec       = $gemspec
end


