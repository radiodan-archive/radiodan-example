require 'eventmachine'
require 'now_playing_client'
require 'bbc_service_map'

class TrackAvoider
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @avoiding_track = @options[:avoiding_track]
    @avoiding = false
  end

  def call(player)
    @player = player

    EM.run do
      @now_playing_client = NowPlayingClient.new

      # When avoid event fired, stash the current
      # station's Track object and wait until the
      # current playing song is finished
      player.register_event :avoid do |type|

        # Only Avoid tracks
        return unless type == :track

        if @avoiding
          logger.info "Already avoiding"
        else
          logger.info "AVOID!"

          @avoided_track = player.playlist.tracks
          logger.info "Current playlist.tracks #{@avoided_track}"
          logger.info "replacement_tracks #{replacement_tracks}"

          station_id        = current_station_id
          now_playing_track = @now_playing_client.now_playing(current_station_id)

          logger.info "current_station_id #{current_station_id}"
          logger.info "now_playing_track #{now_playing_track}"

          track_start_time    = now_playing_track[:start_time].to_i
          track_duration      = now_playing_track['duration']
          time_left_for_track = (track_start_time + track_duration) - Time.now.to_i

          logger.info "track_start_time #{track_start_time}, track_duration #{track_duration}, time_left_for_track #{time_left_for_track}"

          player.playlist.tracks = replacement_tracks
          @avoiding = true

          EventMachine.add_timer(time_left_for_track) do
            logger.info "Track should be finished, reinstating previous station"
            @player.playlist.tracks = @avoided_track
            @avoiding = false
          end
        end
      end
    end
  end

  # This does a look-up from the BBC-provided stream name
  # through the BBC Service Map to get an ID key that
  # matches those provided by the Now Playing service
  def current_station_id
    BBCRD::ServiceMap.lookup(@player.state.tracks.first.attributes[:Name]).programmes_id
  end

  def replacement_tracks
    @avoiding_track
  end
end
