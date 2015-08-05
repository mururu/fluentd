## TODO: consider internal representation

module Fluent
  class NTime
    TYPE = 0

    attr_reader :sec, :nsec

    def initialize(sec, nsec)
      @sec = sec
      @nsec = nsec
    end

    def ==(arg)
      if arg.is_a?(Numeric)
        @sec == arg
      else
        self.sec == arg.sec && self.nsec == arg.nsec
      end
    end

    def self.from_msgpack_ext(data)
      new(*data.unpack('LL'))
    end

    def to_msgpack_ext
      [@sec, @nsec].pack('LL')
    end

    def +(arg)
      if arg.is_a?(Numeric)
        @sec + arg
      else
        nsec = @nsec + arg.nsec
        @sec += arg.sec + nsec / 1000000000
        @nsec += nsec % 1000000000
        self
      end
    end

    def -(arg)
      if arg.is_a?(Numeric)
        @sec - arg
      else
        nsec = @nsec - arg.nsec
        @sec += arg.sec + nsec / 1000000000
        @nsec += nsec % 1000000000
        self
      end
    end

    def >(arg)
      if arg.is_a?(Numeric)
        @sec > arg
      else
        return true if @sec > arg.sec
        return false if @sec < arg.sec
        return true if @nsec > arg.nsec
        false
      end
    end

    def <(arg)
      if arg.is_a?(Numeric)
        @sec < arg
      else
        return true if @sec < arg.sec
        return false if @sec > arg.sec
        return true if @nsec < arg.nsec
        false
      end
    end

    def <=(arg)
      !(self > arg)
    end

    def >=(arg)
      !(self < arg)
    end

    def to_i
      @sec
    end
    alias to_int to_i

    def to_r
      @sec + Rational(@nsec, 1000000000)
    end

    ## for MessagePackFormatter
    def to_msgpack(io)
      @sec.to_msgpack(io)
    end

    def self.now
      time = Time.now
      new(time.to_i, time.nsec)
    end
  end
end
