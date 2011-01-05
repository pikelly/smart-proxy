require "proxy/dhcp/subnet"
require "proxy/dhcp/record"

module Proxy::DHCP
  # represents a DHCP Server
  class Server
    attr_reader :name
    alias_method :to_s, :name

    include Proxy::DHCP
    include Proxy::Log
    include Proxy::Validations

    def initialize(name)
      @name = name
      @subnets = []
      @loaded = false
    end

    def loaded?
      @loaded
    end

    def clear
      @subnets = []
      @loaded  = false
    end

    def load
      @loaded = true
      loadSubnets
    end

    def subnets
      self.load if not loaded?
      @subnets
    end

    # Abstracted Subnet loader method
    def loadSubnets
      self.clear
      logger.debug "Loading subnets for #{name}"
    end

    # Abstracted Subnet data loader method
    def loadSubnetData subnet
      raise "Invalid Subnet" unless subnet.is_a? Proxy::DHCP::Subnet
      logger.debug "Loading subnet data for #{subnet}"
    end

    # Abstracted Subnet options loader method
    def loadSubnetOptions subnet
      logger.debug "Loading Subnet options for #{subnet}"
    end

    # Adds a Subnet to a server object
    def add_subnet subnet
      if find_subnet(subnet.network).nil?
        @subnets << validate_subnet(subnet)
        logger.debug "Added #{subnet} to #{name}"
        return true
      end
      logger.warn "Subnet #{subnet} already exists in server #{name}"
      return false
    end

    def find_subnet value
      subnets.each do |s|
        return s if value.is_a?(String) and s.network == value
        return s if value.is_a?(Proxy::DHCP::Record) and s.include?(value.ip)
        return s if value.is_a?(IPAddr) and s.include?(value)
      end
      return nil
    end

    def find_record record
      subnets.each do |s|
        s.records.each do |v|
          return v if record.is_a?(String) and v.ip == record
          return v if record.is_a?(Proxy::DHCP::Record) and v == record
          return v if record.is_a?(IPAddr) and v.ip == record.to_s
        end
      end
      return nil
    end

    def inspect
      self
    end

    def delRecord subnet, record
      subnet.delete record
    end

  end
end
