class Fluent::NTime
  attr_accessor :sec, :nsec

  def initialize(array)
    @sec = array[0].to_i
    @nsec = array[1].to_i
  end

  def ==(time)
    self.sec == time.sec && self.nsec == time.nsec
  end

  def >(time)
    return true if self.sec > time.sec
    return false if self.sec < time.sec
    self.nsec > time.nsec
  end
  
  def <=(time)
    !(self > time)
  end

  def <(time)
    return true if self.sec < time.sec
    return false if self.sec > time.sec
    self.nsec < time.nsec
  end

  def >=(time)
    !(self < time)
  end

  def localtime
    to_time.localtime
  end

  def to_time
    Time.at(self.sec, self.nsec/100)
  end

  def to_msgpack(packer = nil)
    if packer
      packer.write([@sec, @nsec])
    else
      [@sec, @nsec].to_msgpack
    end
  end

  class << self
    def now
      t = Time.now
      Fluent::NTime.new([t.sec, t.nsec])
    end

    def from_time(time)
      new([time.sec, time.nsec])
    end
  end
end
