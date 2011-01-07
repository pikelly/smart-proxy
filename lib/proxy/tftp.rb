require 'fileutils'
require 'pathname'

module Proxy::TFTP
  extend Proxy::Log

  class << self

    # creates TFTP syslinux config file
    # Assumes we want to use pxelinux.cfg for configuration files.
    def create mac, config
      if mac.nil? or config.nil?
        logger.info "invalid parameters received"
        return false
      end

      FileUtils.mkdir_p syslinux_dir

      File.open(syslinux_mac(mac), 'w') {|f| f.write(config) }
      logger.info "TFTP entry for #{mac} created successfully"
    rescue StandardError => e
      logger.warn "TFTP Adding entry failed: #{e}"
      false
    end

    # removes links created by create method
    # Assumes we want to use pxelinux.cfg for configuration files.
    # parameter is a mac address
    def remove mac
      file = Pathname.new(syslinux_mac(mac))
      if file.exists?
        file.unlink
        logger.debug "TFTP entry for #{mac} removed successfully"
      else
        logger.info "TFTP: Skipping a request to delete a file which doesn't exists"
      end
    rescue StandardError => e
      logger.warn "TFTP removing entry failed: #{e}"
      false
    end

    def fetch_boot_file dst, src
      filename    = src.split("/")[-1]
      destination = Pathname.new("#{SETTINGS.tftproot}/#{dst}-#{filename}")

      # If the file exists then we are done
      return true if destination.exist? and destination.size? > 0

      # Ensure that our image directory exists
      # as the dst might contain another sub directory
      destination.parent.mkpath

      # This makes wget ignore the proxy environment for hosts which are not qualified or IPs
      # Maybe this is not even right
      match = src.match(/:\/\/([^\/]+)/)
      proxy = (match and match[1] !~ /\./) ? "--no-proxy" : ""

      cmd = "wget #{proxy} --no-check-certificate -c -nv #{src} -O \"#{destination}\" >> #{SETTINGS.log_file} 2>&1"
      logger.debug "Executing #{cmd}"
      raise "Access to #{src} failed" unless system "#{cmd}" and destination.size? > 0
    end

    private
    # returns the absolute path
    def path(p = nil)
      p ||= SETTINGS.tftproot || ORIGIN.join("tftpboot").to_s
      # are we running in RAILS or as a standalone CGI?
      dir = defined?(RAILS_ROOT) ? RAILS_ROOT : File.dirname(__FILE__)
      return (p =~ /^\//) ? p : "#{dir}/#{p}"
    end

    def syslinux_mac mac
      "#{syslinux_dir}/01-"+mac.gsub(/:/,"-").downcase
    end

    def syslinux_dir
      "#{path}/pxelinux.cfg"
    end

  end
end
