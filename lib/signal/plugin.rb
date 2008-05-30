
module Signal
  class Plugin
    attr_accessor :mtime

    attr_reader :client

    def initialize(client = nil)
      @client = client
    end

    def callbacks
      self.class.callbacks
    end

    def unload
    end

    class << self
      def callbacks
        @callbacks ||= {}
      end

      def callback(mapping)
        @callbacks ||= {}

        @callbacks.merge!(mapping)
      end

      # Taken from mousehole
      def load(rb, path, client)
        title = File.basename(rb)[/^(\w+)/,1]
        desired_klass_name = title.gsub('_', '')

        # Load the application at the toplevel.  We want everything to work as if it was loaded from
        # the commandline by Ruby.
        klass, klass_name, source = nil, nil, File.read(path)
        begin
          if old_klass_name = Object.constants.grep(/^#{desired_klass_name}$/i)[0]
            Object.send :remove_const, old_klass_name
          end

          source.gsub!('__FILE__', "'" + path + "'")
          eval(source, TOPLEVEL_BINDING, path)
          klass_name = Object.constants.grep(/^#{desired_klass_name}$/i)[0]
          klass = Object.const_get(klass_name)
        rescue Exception => e
          warn "Warning, found broken app: '#{title}': #{Error.pretty_trace(e)}"
          return BrokenPlugin.new(e)
        end

        return unless klass and klass_name

        if klass < Plugin
          begin
            instance = klass.new client
            instance.setup if instance.respond_to? :setup

            instance
          rescue Exception => e
            warn "Warning, found broken app: '#{title}': #{Error.pretty_trace(e)}"
            return BrokenPlugin.new(e)
          end
        end
      end
    end
  end

  class BrokenPlugin < Plugin
    attr_reader :error

    def initialize(error)
      @error = error
    end
  end
end
