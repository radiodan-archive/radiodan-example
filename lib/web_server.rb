class WebServer < Sinatra::Base
  register Sinatra::Async
  def initialize(player)
    @player = player
    super()
  end

  get '/' do
    '<h1>Radiodan</h1>'
  end

  aget '/panic' do
    @player.trigger_event :panic
    body "Panic!"
  end
end
