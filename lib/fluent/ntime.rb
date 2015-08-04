## TODO: consider internal representation

class Fluent::NTime
  TYPE = 0

  attr_reader :sec, :nsec

  def initialize(sec, nsec)
    @sec = sec
    @nsec = nsec
  end

  def ==(ntime)
    self.sec == ntime.sec && self.nsec == ntime.nsec
  end

  def self.from_msgpack_ext(data)
    new(*data.unpack('LL'))
  end

  def to_msgpack_ext
    [@sec, @nsec].pack('LL')
  end
end
