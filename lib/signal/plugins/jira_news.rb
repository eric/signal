
gem 'hpricot'
require 'hpricot'
require 'htmlentities'

require 'open-uri'

require 'ostruct'

class JiraNews < Signal::Plugin
  SLEEP_TIMEOUT = 60
  TARGET_CHANNEL = '#jruby'
  #TARGET_CHANNEL = '#signal'
  JIRA_URL_ROOT = 'http://jira.codehaus.org/'
  JIRA_TAG = 'JRUBY'

  JIRA_BROWSE_URL = "#{JIRA_URL_ROOT}browse/"
  JIRA_PROFILE_URL = "#{JIRA_URL_ROOT}secure/ViewProfile.jspa"
  JIRA_COMMENT_FEED_URL = "#{JIRA_URL_ROOT}sr/jira.issueviews:searchrequest-comments-rss/temp/SearchRequest.xml?&pid=11295&resolution=-1&sorter/field=issuekey&sorter/order=DESC&sorter/field=updated&sorter/order=DESC&tempMax=1"
  JIRA_ISSUE_FEED_URL = "#{JIRA_URL_ROOT}sr/jira.issueviews:searchrequest-xml/temp/SearchRequest.xml?&pid=11295&status=1&sorter/field=issuekey&sorter/order=DESC&tempMax=1"

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
      puts "JiraNews: Shutting down"
      @thread.kill if @thread
    end

    @thread = nil
  end

  def get_newest_issue
    begin
      doc = Hpricot.XML(open(JIRA_ISSUE_FEED_URL))

      item = doc.at('/rss/channel[1]/item[1]')

      OpenStruct.new :jira_id => item.at(:key).inner_text,
        :status => item.at(:status).inner_text,
        :reporter => item.at(:reporter)['username'],
        :assignee => item.at(:assignee)['username'],
        :link => item.at(:link).inner_text,
        :summary => @coder.decode(item.at(:summary).inner_text),
        :title => @coder.decode(item.at(:title).inner_text)

    rescue Exception => e
      puts "JiraNews#get_newest_issue: #{Signal::Error.pretty_trace(e)}"

      nil
    end

  end

  def get_newest_comment
    begin
      doc = Hpricot.XML(open(JIRA_COMMENT_FEED_URL))

      item = doc.at('/rss/channel[1]/item[1]')

      description_html = item.at(:description).inner_html

      ddoc = Hpricot(@coder.decode(description_html))

      # Remove inter-JIRA links
      ddoc.search(%{a[@href^="#{JIRA_BROWSE_URL}"]}).each do |elem|
        elem.parent.replace_child elem, elem.children
      end

      description_table = ddoc / :table
      description_table.remove

      description = ddoc.to_plain_text[/^[\n ]*(.+?)(\n\n|$)/, 1]

      author_anchor = description_table.at(%{a[@href^="#{JIRA_PROFILE_URL}"})

      username = author_anchor[:href][/name=(.+)$/, 1]

      link = item.at(:guid).inner_text

      jira_id = link[/\/browse\/(#{Regexp.escape(JIRA_TAG)}-\d+)/, 1]

      title = @coder.decode(item.at(:title).inner_text)

      title.gsub!(/^RE: /, '')

      OpenStruct.new :jira_id => jira_id,
        :title => title,
        :guid => item.at(:guid).inner_text,
        :author => item.at(:author).inner_text,
        :link => item.at(:link).inner_text,
        :username => username,
        :description => description
    rescue Exception => e
      puts "JiraNews#get_newest_comment: #{Signal::Error.pretty_trace(e)}"

      nil
    end
  end

  def send_issue(issue)
    self.client.send_message TARGET_CHANNEL, "#{issue.title} (New: #{issue.reporter}) <#{issue.link}>"
  end

  def send_comment(comment)
    self.client.send_message TARGET_CHANNEL, "#{comment.title} (Updated: #{comment.username}) <#{comment.link}>"
  end

  def run
    begin
      puts "JiraNews: Initialized"

      last_comment_guid = nil
      last_issue_jira_id = nil

      while true
        if issue = get_newest_issue
          if last_issue_jira_id and issue.jira_id != last_issue_jira_id
            self.send_issue(issue)
          end

          last_issue_jira_id = issue.jira_id
        end

        # Make it so we sleep between each query to make it at least look like
        # we're not flooding the channel
        sleep SLEEP_TIMEOUT / 2

        if comment = get_newest_comment
          if last_comment_guid and comment.guid != last_comment_guid
            self.send_comment(comment)
          end

          last_comment_guid = comment.guid
        end

        # Ditto
        sleep SLEEP_TIMEOUT / 2
      end

    rescue Exception => e
      puts "JiraNews#run: #{Signal::Error.pretty_trace(e)}"
    end
  end
end
