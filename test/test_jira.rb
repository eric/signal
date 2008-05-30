
require 'test/unit/testcase'
require 'lib/signal/jira'

class TestJira < Test::Unit::TestCase
  def setup
    @jira = Signal::Jira.new 'JRUBY', 'http://jira.codehaus.org/'
  end

  def test_title
    title = @jira.get_title '713'

    assert_equal '[JRUBY-713] ZSuper should send the actual argument PLACES, not values', title
  end
end
