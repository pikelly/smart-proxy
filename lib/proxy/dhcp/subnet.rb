require 'ipaddr'
require 'proxy/dhcp/monkey_patches' unless IPAddr.new.respond_to?('to_range')
require 'ping'
require 'proxy/validations'

module Proxy::DHCP
  # Represents a DHCP Subnet
  class Subnet
    attr_reader :network, :netmask, :server, :timestamp
    attr_accessor :options

    include Proxy::DHCP
    include Proxy::Log
    include Proxy::Validations

    def initialize server, network, netmask
      @server    = validate_server server
      @network   = validate_ip network
      @netmask   = validate_ip netmask
      @options   = {}
      @records   = {}
      @timestamp = Time.now if SETTINGS.dhcp_cache_enabled
      @loaded    = false
      raise Proxy::DHCP::Error, "Unable to Add Subnet" unless @server.add_subnet(self)
    end

    def include? ip
      IPAddr.new(to_s).include?(ip.is_a?(IPAddr) ? ip : IPAddr.new(ip))
    end

    def to_s
      "#{network}/#{netmask}"
    end

    def range
      r=valid_range
      "#{r.first.to_s}-#{r.last.to_s}"
    end

    def clear
      @records = {}
      @loaded  = false
    end

    def loaded?
      @loaded
    end

    def size
      records.size
    end

    def load
      self.clear
      return false if loaded?
      @loaded = true
      server.loadSubnetData self
      logger.debug "Lazy loaded #{to_s} records"
    end

    def reload
      clear
      self.load
    end

    def records
      self.load if not loaded?
      @records.values
    end

    def [] record
      self.load if not loaded?
      begin
        return has_mac?(record) if validate_mac(record)
      rescue
        nil
      end
      begin
        return has_ip?(record) if validate_ip(record)
      rescue
        nil
      end
    end

    def has_mac? mac
      records.each {|r| return r if r.mac == mac.downcase }
      return false
    end

    def has_ip? ip
      @records[ip] ? @records[ip] : false
    end

    # adds a record to a subnet
    def add_record record
      unless has_mac?(record.mac) or has_ip?(record.ip)
        @records[record.ip] = record
        logger.debug "Added #{record} to #{to_s}"
        true
      else
        logger.warn "Record #{record} already exists in #{to_s} - can't add again"
        false
      end
    end

    # returns the next unused IP Address in a subnet
    # Pings the IP address as well (just in case its not in Proxy::DHCP)
    def unused_ip
      ips = valid_range.collect{|r| r.to_s}
      used = records.collect{|r| r.ip}
      free_ips = ips - used
      if free_ips.empty?
        logger.warn "No free IPs at #{to_s}"
        return nil
      else
        free_ips.each do |ip|
          logger.debug "searching for free ip - pinging #{ip}"
          # TODO: check for a more faster / portable way
          `ping -q -c 1 #{ip} >/dev/null`
          if $? == 0 or Ping.pingecho(ip,1)
            logger.info "Found a pingable IP(#{ip}) address which does not have a Proxy::DHCP record"
          else
            logger.debug "Found free ip #{ip} out of a total of #{free_ips.size} free ips"
            return ip
          end
        end
      end
    end

    def delete record
      if @records.delete_if{|k,v| v == record}.nil?
        raise Proxy::DHCP::Error, "Removing a Proxy::DHCP Record which doesn't exists"
      end
    end

    def valid_range
      # remove broadcast and network address
      IPAddr.new(to_s).to_range.to_a[1..-2]
    end

    def inspect
      self
    end

    def reservations
      records.collect{|r| r if r.kind == "reservation"}.compact
    end

    def leases
      records.collect{|r| r if r.kind == "lease"}.compact
    end

    def <=> other
      network <=> other.network
    end

  end
end
