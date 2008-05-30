
class NickServ < Signal::Plugin
  PASSWORD = File.read(File.dirname(__FILE__) + '/.nickserv-password').chomp rescue nil

  callback :notice => :handle_notice

  def setup
    if PASSWORD
      puts "NickServ#setup: Registering with NickServ"

      self.client.send_message 'nickserv', "identify #{PASSWORD}"
    else
      puts "NickServ#setup: Could not register with NickServ. No password provided"
    end
  end

  def handle_notice(event)
    if event.from == 'NickServ'
      puts "notice: #{event.from}: #{event.message}"
    end
  end
end
