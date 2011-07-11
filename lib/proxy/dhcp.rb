module Proxy::DHCP
  require "proxy/dhcp/record"
  require "proxy/dhcp/record/lease"
  require "proxy/dhcp/record/reservation"
  require "proxy/dhcp/server"
  Optcode = {"hostname"              => {:code => 12, :kind => "String"    }, # The host's name
             "nextserver"            => {:code => 66, :kind => "String"    }, # From where we download the pxeboot image via TFTP
             "filename"              => {:code => 67, :kind => "String"    }, # The pxeboot image
             "root_server_ip"        => {:code => 2,  :kind => "IPAddress" }, # 172.29.216.241
             "root_server_hostname"  => {:code => 3,  :kind => "String"    }, # s02
             "root_path_name"        => {:code => 4,  :kind => "String"    }, # /vol/s02/solgi_5.10/sol10_hw0910/Solaris_10/Tools/Boot
             "install_server_ip"     => {:code => 10, :kind => "IPAddress" }, # 172.29.216.241
             "install_server_name"   => {:code => 11, :kind => "String"    }, # s02
             "install_path"          => {:code => 12, :kind => "String"    }, # /vol/s02/solgi_5.10/sol10_hw0910
             "sysid_server_path"     => {:code => 13, :kind => "String"    }, # 172.29.216.241:/vol/s02/jumpstart/sysidcfg/sysidcfg_primary
             "jumpstart_server_path" => {:code => 14, :kind => "String"    }} # 172.29.216.241:/vol/s02/jumpstart

  class Error < RuntimeError; end
  class Collision < RuntimeError; end
  class InvalidRecord < RuntimeError; end

  def kind
    self.class.to_s.sub("Proxy::DHCP::","").downcase
  end

end
