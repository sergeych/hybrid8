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


abort 'missing malloc()' unless have_func 'malloc'
abort 'missing free()' unless have_func 'free'

# Give it a name
extension_name = 'h8'

dir_config('v8', '/Users/sergeych/dev/v8', '/Users/sergeych/dev/v8/lib')

dir_config(extension_name)
ok = true

unless have_header('include/v8.h')
  $stderr.puts "can't find v8.h, install libv8 3.25.30+ first"
  ok = false
end

unless have_library('v8_base') && have_library('v8_snapshot') && have_library('v8_libplatform') \
  && have_library('v8_libbase') && have_library('icuuc') && have_library('icudata')
  $stderr.puts "can't find libv8"
  ok = false
end


# This test is actually due to a Clang 3.3 shortcoming, included in OS X 10.9,
# fixed in Clang 3.4:
# http://llvm.org/releases/3.4/tools/clang/docs/ReleaseNotes.html#new-compiler-flags
if try_compile('', '-O6')
  $CFLAGS += ' -Wall -W -O6 -g'
else
  $CFLAGS += ' -Wall -W -O3 -g'
end

CONFIG['CXXFLAGS'] += " --std=c++11"

if ok
  create_makefile(extension_name)
else
  $stderr.puts "*********************************************************************"
  $stderr.puts "Your compiler was unable to link to all necessary libraries"
  $stderr.puts "Please install all prerequisites first"
  $stderr.puts "*********************************************************************"

  raise "Unable to build, correct above errors and rerun"
end

# LIBV8_COMPATIBILITY = '~> 3.30'
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

create_makefile('h8/h8')

