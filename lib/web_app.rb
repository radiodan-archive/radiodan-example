require 'radiodan/sinatra'

class WebApp < Radiodan::Sinatra

  @@stations = []

  configure do
    enable :static
  end

  def self.stations=(list)
    @@stations = list
  end

  get '/' do
    @stations = @@stations
    erb :index
  end

  post '/power' do
    @player.trigger_event :toggle_power
    redirect back
  end

  post '/volume' do
    @player.trigger_event :change_volume, params[:volume]
    redirect back
  end

  post '/station/previous' do
    @player.trigger_event :change_station, :previous
    redirect back
  end

  post '/station/next' do
    @player.trigger_event :change_station, :next
    redirect back
  end

  post '/station/:id' do |id|
    @player.trigger_event :change_station, id
    redirect back
  end
end
