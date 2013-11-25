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
      <script src="http://code.jquery.com/jquery-2.0.3.min.js"></script>
      <script src="/faye/client.js"></script>
      <script>
        var client = new Faye.Client('/faye');
        var subscription = client.subscribe('/info', function(message) {
          console.log(message);
          $('[data-bind="station-name"]').text(stationFromPlaylist(message));
        });

        function stationFromPlaylist(p) {
          return p.tracks[0].Name
        }

        function publish(topic, info) {
          if (info == null) { info = {} }
          client.publish(topic, info);
          console.log('client.publish(%o, %o);', topic, info);
        }

        $('form[data-faye]').on('submit change', function (evt) {
          evt.preventDefault();
          var $form  = $(this);
          var target = $form.attr('action');

          switch(target) {
            case 'volume':  topic   = '/volume';
                            var val = $form.find('[type=range]').val();
                            action  = parseInt(val, 10);
                            break;

            default:        // target is treated as "topic/info"
                            topic  = target.split('/')[0];
                            action = target.split('/')[1];
          }

          topic  = (topic.charAt(0) == '/') ? topic : '/' + topic;
          publish(topic, action);
        });
      </script>
    </body>
    </html>
    html
  end

  template :index do
    <<-html
    <section id="controls">
      <form method="post" action="power" data-faye>
        <span><%= @player.state.state == :play ? "ON" : "OFF" %></span>
        <input type="submit" value="Power" />
      </form>
      <form method="post" action="volume" data-faye>
        <input type="range" name="volume" value="<%= @player.state.volume %>" min="0" max="100" step="1" />
        <input type="submit" value="Change" />
      </form>
    </section><!-- #controls -->
    <section id="stations">
      <p>Current station: <strong data-bind="station-name"><%= @player.state.tracks.first[:Name] %></strong></p>
      <ul>
        <li>
          <form method="post" action="station/previous" data-faye>
            <input type="submit" value="previous" />
          </form>
        </li>
      <% @stations.each do |station| %>
        <li>
          <form method="post" action="station/<%= station[:name] %>" data-faye>
            <input type="submit" name="station-id" value="<%= station[:name] %>" />
          </form>
        </li>
      <% end %>
        <li>
          <form method="post" action="station/next" data-faye>
            <input type="submit" value="next" />
          </form>
        </li>
      </ul>
    </section><!-- #stations -->
    html
  end
end
