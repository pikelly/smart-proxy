class SmartProxy < Sinatra::Base
  def dhcp_setup
    raise "Smart Proxy is not configured to support DHCP" unless SETTINGS.dhcp
    case SETTINGS.dhcp_vendor
    when "isc"
      require 'proxy/dhcp/server/isc'
      unless SETTINGS.dhcp_config and SETTINGS.dhcp_leases \
        and File.exist?(SETTINGS.dhcp_config) and File.exist?(SETTINGS.dhcp_leases)
        log_halt 400, "Unable to find the DHCP configuration or lease files"
      else
        @server  = Proxy::DHCP::ISC.new({:name => "127.0.0.1",
                                        :config => File.read(SETTINGS.dhcp_config),
                                        :leases => File.read(SETTINGS.dhcp_leases)})
      end
    else
      log_halt 400, "Unrecognised or missing DHCP vendor type: #{SETTINGS.dhcp_vendor.nil? ? "MISSING" : SETTINGS.dhcp_vendor}"
    end
    @subnets = @server.subnets
  rescue => e
    log_halt 400, e.to_s
  end

  helpers do
    def load_subnet
      @subnet  = @server.find_subnet(params[:network])
      log_halt 404, "Subnet #{params[:network]} not found" unless @subnet
      @subnet
    end
  end

  before do
    dhcp_setup if request.path_info =~ /dhcp/
  end

  get "/dhcp" do
    begin
      if request.accept.include?("application/json")
        content_type :json

        log_halt 404, "No subnets found on server @{name}" unless @subnets
        @subnets.map{|s| {:network => s.network, :netmask => s.netmask }}.to_json
      else
        erb :"dhcp/index"
      end
    rescue => e
      log_halt 400, e.to_s
    end
  end

  get "/dhcp/:network" do
    begin
      load_subnet
      erb :"dhcp/show"
    rescue => e
      log_halt 400, e.to_s
    end
  end

  get "/dhcp/:network/unused_ip" do
    begin
      content_type :json
      ({:ip => load_subnet.unused_ip}).to_json
    rescue => e
      log_halt 400, e.to_s
    end
  end

  get "/dhcp/:network/:record" do
    begin
      content_type :json
      record = load_subnet[params[:record]]
      log_halt 404, "Record #{params[:network]}/#{params[:record]} not found" unless record
      record.options.to_json
    rescue => e
      log_halt 400, e.to_s
    end
  end

  # create a new record in a network
  post "/dhcp/:network" do
    begin
      content_type :json
      log_halt 400, "Record #{params[:network]}/#{params[:ip]} already exists" if @server.find_record(params[:ip])
      @server.addRecord({ :mac=> params[:mac], :nextserver=> params[:nextserver],
                        :hostname=>params[:name], :filename=> params[:filename],
                        :name=>params[:name], :ip=>params[:ip]})
    rescue => e
      log_halt 400, e.to_s
    end
  end

  # delete a record from a network
  delete "/dhcp/:network/:record" do
    begin
      record = load_subnet[params[:record]]
      log_halt 404, "Record #{params[:network]}/#{params[:record]} not found" unless record
      @server.delRecord @subnet, record
      if request.accept.include?("application/json")
        content_type :json
      else
        redirect "/dhcp/#{params[:network]}"
      end
    rescue Exception => e
      log_halt 400, e.to_s
    end
  end
end
