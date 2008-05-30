module Signal
  class Error
    class << self
      def pretty_trace(e)
        backtrace = e.backtrace || [ '<empty backtrace>' ]

        message = "#{e.backtrace[0]}: #{e.message} (#{e.class})"

        if e.backtrace.length > 1
          message << "\n\t" << e.backtrace[1..-1].join("\n\t")
        end

        message
      end
    end
  end
end
