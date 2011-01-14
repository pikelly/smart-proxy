class SmartProxy
require "proxy/dns/bind"
def setup(opts)
  @server = Proxy::DNS::Bind.new(opts)
end

post "/dns/" do
  fqdn  = params[:fqdn]
  value = params[:value]
  type  = params[:type]
  begin
    setup({:fqdn => fqdn, :value => value, :type => type})
    status = @server.create
    log_halt 400, "DNS create failed for #{fqdn}" unless status
  rescue Exception => e
    log_halt 400, e.to_s
  end
end

delete "/dns/:value" do
  case params[:value]
  when /.in-addr.arpa$/
    type = "PTR"
    value = params[:value]
  else
    fqdn = params[:value]
  end
  begin
    setup({:fqdn => fqdn, :value => value, :type => type})
    log_halt 400, "DNS delete failed for #{fqdn}" unless @server.remove
  rescue => e
    log_halt 400, e.to_s
    end
  end
end
