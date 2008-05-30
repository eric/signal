
require 'hpricot'
require 'open-uri'
require 'htmlentities'

module Signal
  class Jira
    attr_accessor :prefix, :url_prefix

    def initialize(prefix, url_prefix)
      @prefix = prefix
      @url_prefix = url_prefix
      @coder = HTMLEntities.new
    end

    def jira_id?(jira_id)
      jira_id =~ /^#{Regexp.quote(@prefix)}-\d+$/i
    end

    def xml_url(jira_id)
      "#{@url_prefix}/si/jira.issueviews:issue-xml/#{jira_id}/#{jira_id}.xml"
    end

    def get_title(jira_id)
      jira_id = "#{@prefix}-#{jira_id}" if jira_id =~ /^\d+$/

      unless jira_id =~ /^#{Regexp.quote(@prefix)}-\d+$/
        raise "Invalid JIRA id: #{jira_id}"
      end

      url = xml_url jira_id

      doc = Hpricot(open(url))

      title = @coder.decode(doc.at('rss/channel/item/title').inner_text)
      status = doc.at('rss/channel/item/status').inner_text

      "#{title} (#{status}) <#{@url_prefix}browse/#{jira_id}>"
    end
  end
end


class JiraTitle < Signal::Plugin
  callback :privmsg => :handle_privmsg

  def setup
    @jira = Signal::Jira.new 'JRUBY', 'http://jira.codehaus.org/'

    puts "Loaded JiraTitle"
  end

  def handle_privmsg(event)
    if @jira.jira_id? event.message
      jira_id = event.message

      #puts "url = #{@jira.xml_url(jira_id)}"

      title = @jira.get_title(jira_id)

      respond_to event, @jira.get_title(jira_id)
    end
  end

  def respond_to(event, message)
      to = event.channel
      to = event.from if event.channel == @client.nick

      self.client.send_message to, message
  end
end
