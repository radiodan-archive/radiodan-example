require 'thin'
require 'faye'

class FayeWebServer
  include Radiodan::Logging

  def initialize(*config)
    @klass   = config.shift
    @options = config.shift || {}
    @port    = @options.fetch(:port, 3000)
  end

  def call(player)
    klass = @klass
    Faye::WebSocket.load_adapter('thin')
    Thin::Server.start('0.0.0.0', @port, :signals => false) do
      use Faye::RackAdapter, :mount => '/faye', :timeout => 25
      run klass.new(player)
    end
  end
end
