# Represents a playable radio station
# Including playlist and stream expiry
require "radiodan/playlist"
require "rest-client"

class RadioStation
  STATIONS = {
    :'1'   => { :bbc_id => 'radio1',       :title => 'BBC Radio 1'         },
    :'1x'  => { :bbc_id => '1xtra',        :title => 'BBC Radio 1xtra'     },
    :'2'   => { :bbc_id => 'radio2',       :title => 'BBC Radio 2'         },
    :'3'   => { :bbc_id => 'radio3',       :title => 'BBC Radio 3'         },
    :'4'   => { :bbc_id => 'radio4',       :title => 'BBC Radio 4'         },
    :'4lw' => { :bbc_id => 'radio4/lw',    :title => 'BBC Radio Long Wave' },
    :'4x'  => { :bbc_id => 'radio4extra',  :title => 'BBC Radio 4 Xtra'    },
    :'5l'  => { :bbc_id => '5live',        :title => 'BBC Radio 5 Live'    },
    :'6'   => { :bbc_id => '6music',       :title => 'BBC Radio 6 Music'   },
    :'an'  => { :bbc_id => 'asiannetwork', :title => 'BBC Asian Network'   },
    :'ws'  => { :bbc_id => 'worldservice', :title => 'BBC World Service'   },
  }

  URL = "http://www.bbc.co.uk/radio/listen/live/r%s_aaclca.pls"

  def self.list
    STATIONS.map do |id,props|
      if id == :'ws'
        RadioStation.new(id.to_s, props[:bbc_id], props[:title], "http://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-eieuk")
      else
        RadioStation.new(id.to_s, props[:bbc_id], props[:title])
      end
    end
  end

  def initialize(id, bbc_id, title=nil, url=nil)
    @id     = id
    @bbc_id = bbc_id
    @title  = title
    @url    = url || URL
  end

  def stream_id
    @id
  end

  def bbc_id
    @bbc_id
  end

  def title
    @title
  end

  def playlist
    Radiodan::Playlist.new(tracks: tracks)
  end

  def tracks
    Radiodan::Track.new(:file => stream_url, :id => bbc_id)
  end

  def stream_url
    pls_file.match(/^File1=(.*)$/)[1]
  end

  def expires
    date = nil
    end_time_secs = stream_url.match(/e=([\d]*)/)
    date = DateTime.strptime(end_time_secs[1],'%s') if end_time_secs && end_time_secs.length > 0
    date
  end

  def pls_url
    @url % stream_id
  end

  def reset!
    @pls_file = nil
  end

  private
  def pls_file
    unless @pls_file
      @pls_file = RestClient.get(pls_url)
    end
    @pls_file
  end
end
