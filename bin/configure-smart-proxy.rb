#!/usr/bin/ruby

require 'rubygems'
require 'pathname'

unless Process.euid == 0
  puts "Please run the configuration utility as root"
  exit -1
end

unless Gem.available?("smart-proxy")
  puts "The smart-proxy gem does not apear to be installed"
  exit -1
end

location = Pathname.new(Gem.source_index.find_name("smart-proxy").last.full_gem_path)

%x{getent passwd smart-proxy >/dev/null 2>&1}
unless $?.success?
  puts "Adding the smart-proxy user and group"
  puts %x{adduser --quiet --system --disabled-password --home /nonexistent --no-create-home --shell /bin/false --group smart-proxy}
  unless $?.success?
    puts "Failed to create the smart-proxy user and group"
    puts "Adduser exited with a status of #{$?.exitstatus}"
    exit -1
  end
end

puts "Granting smart-proxy account access to the configuration files" 
Pathname.new("/etc/smart-proxy").make_symlink location.join("config") unless File.exist? "/etc/smart-proxy"
puts %x{cp #{location}/extra/settings.yml.example /etc/smart-proxy/settings.yml}
puts %x{chown smart-proxy:smart-proxy /etc/smart-proxy/*}

unless File.exist? "/etc/init.d/smart-proxy"
  puts "Installing the smart-proxy as a daemon"
  puts %x{cp #{location}/extra/smart-proxy /etc/init.d}
  unless $?.success?
    puts "Unable to install rc script"
    exit -1
  end
  File.open("/etc/default/smart-proxy", "w") do |f|
    f.puts "ENABLE_SMART_PROXY=no"
  end
end

puts %x{update-rc.d smart-proxy defaults}
unless $?.success?
  puts "Unable to activate rc script"
  exit -1
end

puts "Creating the logging directories"
[location.join("log"), "/var/log/smart-proxy"].each do |path|
  dir = Pathname.new(path)
  unless dir.exist?
    dir.mkpath
    FileUtils.chown "smart-proxy", "smart-proxy", path
  end
end

puts "Please now edit /etc/smart-smart-proxy/settings.yml and /etc/default/smart-proxy"