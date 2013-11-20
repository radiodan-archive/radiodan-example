require 'radiodan/sinatra'

class WebApp < Radiodan::Sinatra

  @@stations = []

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
    sleep(1)
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

  template :layout do
    <<-html
    <html>
    <head>
      <title>Radiodan</title>
    </head>
    <body>
      <%= yield %>
    </body>
    </html>
    html
  end

  template :index do
    <<-html
    <section id="controls">
      <form method="post" action="power">
        <span><%= @player.state.state == :play ? "ON" : "OFF" %></span>
        <input type="submit" value="Power" />
      </form>
      <form method="post" action="volume">
        <input type="range" name="volume" value="<%= @player.state.volume %>" min="0" max="100" step="1" />
        <input type="submit" value="Change" />
      </form>
    </section><!-- #controls -->
    <section id="stations">
      <p>Current station: <strong><%= @player.state.tracks.first[:Name] %></strong></p>
      <ul>
        <li>
          <form method="post" action="station/previous">
            <input type="submit" value="previous" />
          </form>
        </li>
      <% @stations.each do |station| %>
        <li>
          <form method="post" action="station/<%= station[:name] %>">
            <input type="submit" name="station-id" value="<%= station[:name] %>" />
          </form>
        </li>
      <% end %>
        <li>
          <form method="post" action="station/next">
            <input type="submit" value="next" />
          </form>
        </li>
      </ul>
    </section><!-- #stations -->
    html
  end
end
