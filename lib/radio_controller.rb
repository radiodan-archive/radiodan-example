class RadioController
  include Radiodan::Logging

  def initialize(*config)
  end

  def call(player)
    @player = player
    logger.debug "RadioController middleware"

    player.register_event :toggle_power do
      power!
    end

    player.register_event :change_volume do |volume|
      volume(volume)
    end
  end

  def power!
    logger.info "Toggle power"
    if @player.playlist.state == :play
      @player.pause
    else
      @player.play
    end
  end

  def volume(value)
    @player.playlist.volume = value
  end
end
