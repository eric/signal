
require 'thread'

module Signal
  class Reloader
    attr_reader :callbacks

    def initialize(paths, client)
      @paths = [ paths ].flatten
      @items = {}
      @callbacks = {}
      @client = client

      @mutex = Mutex.new

      @last_refresh = Time.now
      @min_interval = 5

      load_all :force
    end

    def path=(paths)
      @paths = [ paths ].flatten

      load_all :force
    end

    def get(name)
      refresh_all

      unless item = @items[name]
        raise "The item specified '#{name}' could not be located."
      end

      item
    end

    def each(&block)
      refresh_all

      @items.each_value &block
    end

    def load_all action = nil
      @mutex.synchronize do
        @paths.each do |dir|
          Dir[File.join(dir, '*.rb')].each do |path|
            path = File.expand_path(path)

            dir, rb = *File.split(path)

            unless action == :force
              next if @items[rb] and File.mtime(path) <= @items[rb].mtime
            end

            load_item dir, rb
          end
        end

        register_callbacks

        @last_refresh = Time.now
      end
    end

    def refresh_all
      return if (Time.now - @last_refresh).to_i < @min_interval
      load_all
    end

    def load_item dir, rb
      if @items.has_key? rb
        @items[rb].unload

        puts "Reloading #{rb}"
      else
        puts "Loading #{rb}"
      end

      path = File.join(dir, rb)

      item = @items[rb] = Plugin.load(rb, path, @client)
      item.mtime = File.mtime(path)

      item
    end

    def register_callbacks
      new_callbacks = Hash.new do |h,k|
        h[k] = []
      end

      @items.each do |k, item|
        item.callbacks.each do |callback, method|
          new_callbacks[callback] << item.method(method)
        end
      end

      new_callbacks.each_key do |cb|

        IRCEvent.add_callback cb.to_s do |event|
          # Refresh what's there
          self.refresh_all

          self.callbacks[cb].each do |m|
            begin
              m.call event
            rescue Exception => e
              puts "#{cb}/#{m}: #{e}"
            end
          end
        end
      end

      removed_callbacks = @callbacks.keys - new_callbacks.keys

      removed_callbacks.each do |callback|
        IRCEvent.add_callback callback { |e| }
      end

      # Make sure if we start without anything, we'll always be able to load
      # plugins when they are available
      if new_callbacks.empty?
        IRCEvent.add_callback 'privmsg' do |e|
          # Refresh plugins
          self.refresh_all
        end
      end

      @callbacks = new_callbacks
    end
  end
end
