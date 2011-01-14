#!/usr/bin/ruby
require "rubygems"
require "pathname"
require 'etc'

SERVICE = ARGV[0] == "--service"

ORIGIN = Pathname.new(__FILE__).dirname.parent.realpath

# If we have been installed as an application in /usr/sbin then our libraries are in /usr/lib/smart-proxy/lib
lib = ORIGIN.to_s == "/usr" ? ORIGIN.join("lib", "smart-proxy", "lib") : ORIGIN.join("lib").to_s
$LOAD_PATH.unshift lib

require "sinatra/base"
require "proxy"
require "sinatra-patch"
require "json"
require 'openssl'
require 'webrick/https'

class SmartProxy < Sinatra::Base
  include Proxy::Log
  path = ORIGIN

  set :root,    path.to_s
  set :views,   path.join('views').to_s
  set :public,  path.join('public').to_s
  set :logging, true
  set :run,     true

  helpers do
    def log_halt code, message
      logger.error message
      halt code, message
    end
  end

  before do
  # If we reach here then the peer is verified and cannot be spoofed
    if SETTINGS.trusted_hosts
      unless SETTINGS.trusted_hosts.include? request.host
        log_halt 403, "Untrusted client #{request.host} attempted to access #{request.path_info}. Check :trusted_hosts: in settings.yml"
      end
    end
  end

  require "tftp_api"     if SETTINGS.tftp
  require "puppet_api"   if SETTINGS.puppet
  require "puppetca_api" if SETTINGS.puppetca
  require "dns_api"      if SETTINGS.dns
  require "dhcp_api"     if SETTINGS.dhcp
end

# Read the keys as root
begin
  ssl_options = {:SSLEnable            => true,
                 :SSLVerifyClient      => OpenSSL::SSL::VERIFY_PEER,
                 :SSLPrivateKey        => OpenSSL::PKey::RSA.new(File.read(SETTINGS.ssl_private_key)),
                 :SSLCertificate       => OpenSSL::X509::Certificate.new(File.read(SETTINGS.ssl_certificate)),
                 :SSLCACertificateFile => SETTINGS.ssl_ca_file
  }
rescue => e
  puts "Unable to access the SSL keys. Are the values correct in settings.yml and do permissions allow reading?"
end

if SERVICE
  begin
    require 'win32/daemon'
    include Win32

    logpath = SETTINGS.log_file
    $stdout.reopen(logpath, "a")
    $stdout.sync = true
    $stderr.reopen($stdout)
    puts "#{Time.now}: Service is starting"

    class Daemon
      attr_writer :ssl_options
      def service_init
        puts "#{Time.now}: Service is initializing"
      end

      def service_main(*args)
        puts "#{Time.now}: Service is running"
        SmartProxy.run!({}, @ssl_options)
        puts "#{Time.now}: Service is terminating"

     end

      def service_stop
       puts "#{Time.now}: Service stopped"
        exit!
      end
    end

    daemon = Daemon.new
    daemon.ssl_options = ssl_options
    daemon.mainloop
  rescue Exception => err
    File.open(SERVICELOG,(File::APPEND|File::CREAT|File::WRONLY)){ |f| f.puts " ***Daemon failure #{Time.now} err=#{err} " }
    raise
  end
else
  # Drop root privileges
  unless Gem.win_platform?
    if SETTINGS.group and Process::uid == 0
      unless (grent = Etc.getgrnam(SETTINGS.group) rescue nil)
        puts "Failed to find the GID of group #{SETTINGS.group}"
        exit -1
      end
      Process.egid = grent.gid
    end
    if SETTINGS.user and Process::uid == 0
      unless (pwent = Etc.getpwnam(SETTINGS.user) rescue false)
        puts "Failed to find the UID of user #{SETTINGS.user}"
        exit -1
      end
      Process.euid = pwent.uid
    end
  end
  SmartProxy.run!({}, ssl_options)
end
