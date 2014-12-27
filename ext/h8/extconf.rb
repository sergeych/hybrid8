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

begin

  # Give it a name
  extension_name = 'h8'

  chk_headers = ['include/v8.h']
  chk_libs    = %w(v8_base v8_libbase v8_libplatform v8_snapshot icudata icui18n icuuc)

  case RbConfig::CONFIG['target_os']
    when /darwin/
      v8_path = ENV['V8_3_31_ROOT'] or raise "Please give me export V8_3_31_ROOT=..."
      # dir_config('v8', '/Users/sergeych/dev/v8', '/Users/sergeych/dev/v8/out/native')
      dir_config('v8', v8_path, v8_path+'/out/native')
      CONFIG['CXXFLAGS'] += ' --std=c++11'
    else
      # example linux package https://github.com/porzione/v8-git-debian
      dir_config('v8', '/usr/include/libv8-3.31', '/usr/lib/libv8-3.31')
      # force static, but system icu
      $LOCAL_LIBS = chk_libs.reject { |l| l.match /^icu/ }.map { |l| "-l#{l}" }.join(" ")
  end

  dir_config(extension_name)

  chk_headers.each do |h|
    unless have_header(h)
      raise "can't find v8 header '#{h}', install libv8 3.31+ first"
    end
  end

  chk_libs.each do |lib|
    unless have_library(lib)
      raise "can't find v8 lib '#{lib}'"
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

# create_makefile('h8/h8')
  create_makefile(extension_name)
rescue
  $stderr.puts "*********************************************************************"
  $stderr.puts "\n#{$!}\n\n"
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


