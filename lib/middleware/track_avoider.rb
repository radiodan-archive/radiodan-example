require 'eventmachine'
require 'now_playing_client'
require 'bbc_service_map'

class TrackAvoider
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @avoiding_track = @options[:avoiding_track]
    @avoiding = false
    @avoiding_timer = nil
  end

  def call(player)
    @player = player

    EM.run do
      @now_playing_client = NowPlayingClient.new

      # Cancel avoiding when station is changed
      player.register_event :change_station do |id|
        logger.info "Cancelling avoidance due to station change"
        @avoiding_timer.cancel if @avoiding_timer
        logger.info "cancelled @avoiding_timer"
        @avoided_track = nil
        logger.info "niled @avoided_track"
        @avoiding = false
        logger.info "falsified @avoiding"
      end

      # When avoid event fired, stash the current
      # station's Track object and wait until the
      # current playing song is finished
      player.register_event :avoid do |type|
        # Only Avoid tracks
        begin
          avoid! unless type != :track
        rescue
          logger.error "Error avoiding, stop avoidance"
          @avoiding_timer.cancel if @avoiding_timer
          @avoided_track = nil
          @avoiding = false
        end
      end
    end
  end

  def avoid!
    if @avoiding
      logger.info "Already avoiding"
    else
      logger.info "AVOID!"

      @avoided_track = @player.playlist.tracks
      logger.info "Current playlist.tracks #{@avoided_track}"
      logger.info "replacement_tracks #{replacement_tracks}"

      now_playing_track = @now_playing_client.now_playing(current_station_id)

      logger.info "current_station_id #{current_station_id}"
      logger.info "now_playing_track #{now_playing_track}"

      track_start_time    = now_playing_track[:start_time].to_i
      track_duration      = now_playing_track['duration']
      time_left_for_track = (track_start_time + track_duration) - Time.now.to_i

      logger.info "track_start_time #{track_start_time}, track_duration #{track_duration}, time_left_for_track #{time_left_for_track}"

      @player.playlist.tracks = replacement_tracks
      @avoiding = true

      @avoiding_timer = EventMachine::Synchrony.add_timer(time_left_for_track) do
        logger.info "Track should be finished, reinstating previous station"
        @player.playlist.tracks = @avoided_track
        @avoiding = false
      end
    end
  end

  def current_station_id
    @player.playlist.tracks.first[:id]
  end

  def replacement_tracks
    @avoiding_track
  end
end
