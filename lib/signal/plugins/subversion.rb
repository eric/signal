

gem 'hpricot'
require 'hpricot'
require 'htmlentities'

require 'open-uri'

require 'ostruct'

class Subversion < Signal::Plugin
  SLEEP_TIMEOUT = 60
  TARGET_CHANNEL = '#jruby'
  #TARGET_CHANNEL = '#signal'
  SUBVERSION_URL = 'http://svn.codehaus.org/jruby/'

  CHANGELOG_VIEWER_URL = 'http://svn.jruby.codehaus.org/changelog/jruby/?cs='

  def logger message
    puts "#{self.class.name}: #{message}"
  end

  def setup
    if client.channels.detect { |channel| channel.name == TARGET_CHANNEL }.nil?
      client.add_channel TARGET_CHANNEL
    end

    @coder = HTMLEntities.new

    @thread = Thread.new do
      self.run
    end
  end

  def unload
    if @thread
      self.logger "Shutting down"
      @thread.kill if @thread
    end

    @thread = nil
  end

  def get_latest_checkin
    begin
      doc = Hpricot.XML(`svn log "#{SUBVERSION_URL}" --non-interactive --limit 1 --xml`)

      entry = doc.at('/log/logentry[1]')

      message = @coder.decode(entry.at(:msg).inner_text)

      first_line = shrink_message message

      revision = entry[:revision].to_i

      OpenStruct.new :revision => revision,
        :message => message,
        :first_line => first_line,
        :author => entry.at(:author).inner_text,
        :changelog_url => "#{CHANGELOG_VIEWER_URL}#{revision}"

    rescue Exception => e
      self.logger "#get_last_checkin: #{Signal::Error.pretty_trace(e)}"

      nil
    end
  end

  def shrink_message(message)
    first_line = message[/^[\s\n]*(.+?)(\n|$)/, 1]

    while first_line.size > 400
      first_line = first_line[/^(.+\.)\s/, 1]
    end

    first_line
  end

  def send_checkin(checkin)
    self.client.send_message TARGET_CHANNEL, "r#{checkin.revision}: #{checkin.first_line} (Checkin: #{checkin.author}) <#{checkin.changelog_url}>"
  end

  def run
    begin
      self.logger "Initialized"

      last_revision = nil

      while true
        if checkin = get_latest_checkin
          if last_revision and checkin.revision != last_revision
            self.send_checkin(checkin)
          end

          last_revision = checkin.revision
        end

        sleep SLEEP_TIMEOUT
      end

    rescue Exception => e
      self.logger "#run: #{Signal::Error.pretty_trace(e)}"
    end
  end
end
