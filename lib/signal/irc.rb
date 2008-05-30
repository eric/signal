
require 'rubygems'

gem 'Ruby-IRC'
require 'IRC'

class IRCEvent
  alias_method :standard_process, :process
  alias_method :standard_initialize, :initialize

  def initialize(line)
    line.sub!(/^:/, '')
    mess_parts = line.split(':', 2);
    # mess_parts[0] is server info
    # mess_parts[1] is the message that was sent
    @message = mess_parts[1]

    # Fixed this regex to work with freenode.
    # Added '/' and '='
    @stats = mess_parts[0].scan(/[-\w.\#\@\+\/=]+/)

    if @stats[0].match(/^PING/)
      @event_type = 'ping'
    elsif @stats[1] && @stats[1].match(/^\d+/)
      @event_type = EventLookup::find_by_number(@stats[1]);
      @channel = @stats[3]
    else
      @event_type = @stats[2].downcase if @stats[2]
    end

    if @event_type != 'ping'
      @from    = @stats[0]
      @user    = IRCUser.create_user(@from)
    end
    @hostmask = @stats[1] if %W(privmsg join).include? @event_type
    @channel = @stats[3] if @stats[3] && !@channel
    @target  = @stats[5] if @stats[5]
    @mode    = @stats[4] if @stats[4]



    # Unfortunatly, not all messages are created equal. This is our
    # special exceptions section
    if @event_type == 'join'
      @channel = @message
    end
  end

  def process
    standard_process
  end
end

class IRCConnection
  def IRCConnection.remove_IO_socket(socket)
    socket.close
    @@readsockets.delete_if {|item| item == socket }
  end
end

