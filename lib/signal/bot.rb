
module Signal
  class Bot
    def initialize(nick, server, jira_prefix, jira_url_prefix, opts = {})
      realname = opts[:realname] || nick
      port = opts[:port] || 6667
      channel = opts[:channel]

      @client = IRC.new nick, server, port, realname

      plugin_dir = File.expand_path(File.dirname(__FILE__) + "/plugins")

      @reloader = nil

      IRCEvent.add_callback 'endofmotd' do |event|
        if channel
          puts ".=> Joining #{channel}" 
          @client.add_channel(channel)
        end

        puts ".=> Logged into #{server}:#{port}"

        @reloader = Signal::Reloader.new plugin_dir, @client
      end
    end

    def connect
      @client.connect
    end
  end
end
