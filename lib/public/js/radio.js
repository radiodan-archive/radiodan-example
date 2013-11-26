var client = new Faye.Client('/faye');

var currentStationId;

if (client) {
  $('body').attr('data-faye-enabled', 'data-faye-enabled');
}

var subscription = client.subscribe('/info', function(message) {
  console.log(message);
  $('[data-power-state]').attr('data-power-state', stateClassFromPlaylist(message));
  $('[data-bind="state"]').text(stateLabelFromPlaylist(message));
  $('[data-bind="station-name"]').text(stationFromPlaylist(message));
  $('[data-bind="volume"]').text(volumeFromPlaylist(message));

  // Update current station
  $('#stations li').removeClass('active');
  $('[data-station-id="' + stationIdFromPlaylist(message) + '"]').addClass('active');

  newStationId = stationIdFromPlaylist(message);

  if (newStationId != currentStationId) {
    clearNowPlaying();
  }

  currentStationId = newStationId;
});

var nowPlayingSub = client.subscribe('/now_playing', function(message) {
  console.log(message);
  if (message.station_id == currentStationId) {
    tmpl('#now-playing-template', '#now-playing', message);
  } else {
    clearNowPlaying();
  }
});

function clearNowPlaying() {
  $('#now-playing').html('');
}

var tmpl = function (tmplSel, targetSel, data) {
  var $target  = $(targetSel),
      template = $(tmplSel).text(),
      output;

  if (($target.length == 0) || (template == '')) { return; }

  var output = Mustache.render(template, data);
  $target.html(output);
}

function stationFromPlaylist(p) {
  return p.tracks[0].Name;
}

function stationIdFromPlaylist(p) {
  return p.tracks[0].id;
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
