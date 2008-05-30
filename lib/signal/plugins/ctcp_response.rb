
class CtcpResponse < Signal::Plugin
  VERSION = "Ruby-IRC/1.0.7 signal/#{Signal::VERSION} - talk to _eric"

  callback :privmsg => :handle_privmsg

  def setup
  end

  def handle_privmsg(event)
    if event.message =~ /^\001(.+)\001$/
      command, args = *$1.split(/\s/, 2)

      case command
      when 'PING'
        user_ctcp_response(event, command, args)
      when 'VERSION'
        user_ctcp_response(event, command, VERSION)
      end
    end
  end

  def user_ctcp_response(event, type, message)
    self.client.send_notice event.from, "\001#{type} #{message}\001"
  end
end

