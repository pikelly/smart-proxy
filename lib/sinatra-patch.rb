module Sinatra
  class Base
    # Run the Sinatra app as a self-hosted server using
    # Thin, Mongrel or WEBrick (in that order)
    def self.run!(options={},ssl_options={})
      set options
      handler      = detect_rack_handler
      handler_name = handler.name.gsub(/.*::/, '')
      puts "== Sinatra/#{Sinatra::VERSION} has taken the stage " +
           "on #{port} for #{environment} with backup from #{handler_name}" unless handler_name =~/cgi/i
      handler.run self, {:Host => bind, :Port => port}.merge(ssl_options) do |server|
        [:INT, :TERM].each { |sig| trap(sig) { quit!(server, handler_name) } }
        set :running, true
      end
    rescue Errno::EADDRINUSE => e
      puts "== Someone is already performing on port #{port}!"
    end
  end
end
