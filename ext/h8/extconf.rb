# TTCrypt thrift cryptoutuls package
# Copyright (C) 2014 by Thrift.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "mkmf"

cxx11flag = " --std=c++11"

$CXXFLAGS = CONFIG["CXXFLAGS"] unless defined?($CXXFLAGS)
$CXXFLAGS += cxx11flag unless $CXXFLAGS.include?(cxx11flag)

abort 'missing malloc()' unless have_func 'malloc'
abort 'missing free()' unless have_func 'free'

# Give it a name
extension_name = 'h8'

ok = true

chk_headers = ['include/v8.h']

case RbConfig::CONFIG['target_os']
when /darwin/
  chk_libs = %w(v8_base v8_libbase v8_libplatform v8_snapshot icudata icui18n icuuc)
  dir_config('v8', '/Users/sergeych/dev/v8', '/Users/sergeych/dev/v8/lib')
else
  # linux:
  # shared libv8.so, system shared libicu, static v8_libplatform
  chk_libs = %w(v8 icudata icui18n icuuc v8_libplatform)
  dir_config('v8', '/usr/include/libv8-3.31', '/usr/lib/libv8-3.31')
end

dir_config(extension_name)

chk_headers.each do |h|
  unless have_header(h)
    $stderr.puts "can't find v8 header '#{h}', install libv8 3.31+ first"
    ok = false
    break
  end
end

chk_libs.each do |lib|
  unless have_library(lib)
    $stderr.puts "can't find v8 lib '#{lib}'"
    ok = false
    break
  end
end

# This test is actually due to a Clang 3.3 shortcoming, included in OS X 10.9,
# fixed in Clang 3.4:
# http://llvm.org/releases/3.4/tools/clang/docs/ReleaseNotes.html#new-compiler-flags
# if try_compile('', '-O6')
#   $CFLAGS += ' -Wall -W -O6 -g'
# else
#   $CFLAGS += ' -Wall -W -O3 -g'
# end

if ok
  # create_makefile('h8/h8')
  create_makefile(extension_name)
else
  $stderr.puts "*********************************************************************"
  $stderr.puts "Your compiler was unable to link to all necessary libraries"
  $stderr.puts "Please install all prerequisites first"
  $stderr.puts "*********************************************************************"

  raise "Unable to build, correct above errors and rerun"
end

# LIBV8_COMPATIBILITY = '~> 3.31'
#
# begin
#   require 'rubygems'
#   gem 'libv8', LIBV8_COMPATIBILITY
# rescue Gem::LoadError
#   warn "Warning! Unable to load libv8 #{LIBV8_COMPATIBILITY}."
# rescue LoadError
#   warn "Warning! Could not load rubygems. Please make sure you have libv8 #{LIBV8_COMPATIBILITY} installed."
# ensure
#   require 'libv8'
# end
#
# Libv8.configure_makefile


