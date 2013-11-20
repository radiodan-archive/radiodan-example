require 'radiodan/sinatra'

class WebApp < Radiodan::Sinatra
  get '/' do
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
    html
  end
end
