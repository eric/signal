
require 'sandbox'

class Evaluator < Signal::Plugin
  SANDBOX_RECYCLE_TIMEOUT = 5 * 60
  SANDBOX_TIMEOUT = 10

  callback :privmsg => :handle_privmsg

  def setup
  end

  def handle_privmsg(event)
    if event.message =~ /^\?eval (.+)$/
      self.box_eval(event, $1)
    elsif event.message =~ /^\?reset$/
      self.reset!
    end
  end

  def reset!
    puts "Evaluator#reset!: Resetting sandbox"
    @box = Sandbox.safe :timeout => SANDBOX_TIMEOUT
    @box_errors = %w[StandardError ScriptError].map { |x| @box.eval(x) }
    @last_used = Time.now
  end

  def box
    if @box.nil? || (@last_used + SANDBOX_RECYCLE_TIMEOUT) < Time.now
      self.reset!
    end

    @last_used = Time.now
    @box
  end

  def box_eval(event, statement)
    begin
      result = self.box.eval <<-EOE
        class Main
          #{statement}
        end.inspect
      EOE

      respond_to event, "=> #{result}"
    rescue Sandbox::Exception, Sandbox::TimeoutError => e
      respond_to event, e.to_s
    rescue Exception => e
      puts "Evaluator#box_eval: #{statement.inspect}: #{e.class}: #{e}"
    end
  end

  def respond_to(event, message)
      to = event.channel
      to = event.from if event.channel == @client.nick

      if message.length > 400
        message = "#{message[0,400]}..."
      end

      self.client.send_message to, message
  end
end

