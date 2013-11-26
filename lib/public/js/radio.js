var client = new Faye.Client('/faye');

if (client) {
  $('body').attr('data-faye-enabled', 'data-faye-enabled');
}

var subscription = client.subscribe('/info', function(message) {
  console.log(message);
  $('[data-power-state]').attr('data-power-state', stateClassFromPlaylist(message));
  $('[data-bind="state"]').text(stateLabelFromPlaylist(message));
  $('[data-bind="station-name"]').text(stationFromPlaylist(message));
  $('[data-bind="volume"]').text(volumeFromPlaylist(message));
});

function stationFromPlaylist(p) {
  return p.tracks[0].Name;
}

function volumeFromPlaylist(p) {
  return p.volume;
}

function stateLabelFromPlaylist(p) {
  return p.state == "play" ? "ON" : "OFF";
}

function stateClassFromPlaylist(p) {
  return p.state == "play" ? "on" : "off";
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
