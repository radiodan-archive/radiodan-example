require 'json'
class WebServer < Sinatra::Base
  register Sinatra::Async
  
  def initialize(player)
    @player = player
    super()
  end

  aget '/' do
    EM::Synchrony.next_tick do
      body { "<h1>Radiodan</h1><p>#{CGI.escapeHTML(@player.state.inspect)}</p>" }
    end
  end

  aget '/panic' do
    @player.trigger_event :panic
    body "Panic!"
  end
end
