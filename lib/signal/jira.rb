
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'

module Signal
  class Jira
    attr_accessor :prefix, :url_prefix

    def initialize(prefix, url_prefix)
      @prefix = prefix
      @url_prefix = url_prefix
    end

    def jira_id?(jira_id)
      jira_id =~ /^#{Regexp.quote(@prefix)}-\d+$/
    end

    def get_title(jira_id)
      jira_id = "#{@prefix}-#{jira_id}" if jira_id =~ /^\d+$/

      unless jira_id =~ /^#{Regexp.quote(@prefix)}-\d+$/
        raise "Invalid JIRA id: #{jira_id}"
      end

      url = "#{@url_prefix}/si/jira.issueviews:issue-xml/#{jira_id}/#{jira_id}.xml"

      content = open(url) do |io|
        io.read
      end

      rss = RSS::Parser.parse content, false

      rss.items[0].title
    end
  end
end
