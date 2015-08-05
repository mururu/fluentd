require_relative 'helper'
class NTimeTest < Test::Unit::TestCase
  include Fluent

  def setup
    @sec = 100
    @nsec = 200
    @time = NTime.new(@sec, @nsec)
  end

  test '+ NTime' do
    assert_equal(NTime.new(@sec + 1, @nsec + 2), @time + NTime.new(1, 2))
    assert_equal(NTime.new(@sec + 3, @nsec - 2), @time + NTime.new(2, 1000000000 - 2))
  end

  test '+ Integer' do
    assert_equal(@sec + 10, @time + 10)
  end

  test '- NTime' do
    assert_equal(NTime.new(@sec - 1, @nsec - 2), @time - NTime.new(1, 2))
    assert_equal(NTime.new(@sec - 3, 1000000000 - 2), @time - NTime.new(2, @nsec + 2))
  end

  test '- Integer' do
    assert_equal(@sec - 10, @time - 10)
  end

  test '== NTime' do
    assert_true(@time == NTime.new(@sec, @nsec))
    assert_false(@time == NTime.new(@sec + 1, @nsec))
    assert_false(@time == NTime.new(@sec, @nsec + 1))
    assert_false(@time == NTime.new(@sec + 1, @nsec + 1))
  end

  test '== Integer' do
    assert_true(@sec == @time)
    assert_false(@sec == @time + 1)
  end

  test '> NTime' do
    assert_true(@time > NTime.new(@sec - 1, @nsec))
    assert_true(@time > NTime.new(@sec, @nsec - 1))
    assert_true(@time > NTime.new(@sec - 1, @nsec - 1))
    assert_false(@time > NTime.new(@sec + 1, @nsec))
    assert_false(@time > NTime.new(@sec, @nsec + 1))
    assert_false(@time > NTime.new(@sec + 1, @nsec + 1))
    assert_true(@time > NTime.new(@sec - 1, @nsec + 1))
    assert_false(@time > NTime.new(@sec + 1, @nsec - 1))
    assert_false(@time > NTime.new(@sec, @nsec))
  end

  test '> Integer' do
    assert_true(@time > @sec - 1)
    assert_false(@time > @sec)
    assert_false(@time > @sec + 1)
  end

  test '< NTime' do
    assert_true(@time < NTime.new(@sec + 1, @nsec))
    assert_true(@time < NTime.new(@sec, @nsec + 1))
    assert_true(@time < NTime.new(@sec + 1, @nsec + 1))
    assert_false(@time < NTime.new(@sec - 1, @nsec))
    assert_false(@time < NTime.new(@sec, @nsec - 1))
    assert_false(@time < NTime.new(@sec - 1, @nsec - 1))
    assert_true(@time < NTime.new(@sec + 1, @nsec - 1))
    assert_false(@time < NTime.new(@sec - 1, @nsec + 1))
    assert_false(@time < NTime.new(@sec, @nsec))
  end

  test '< Integer' do
    assert_true(@time < @sec + 1)
    assert_false(@time < @sec)
    assert_false(@time < @sec - 1)
  end

  test '>= NTime' do
    assert_true(@time >= NTime.new(@sec - 1, @nsec))
    assert_true(@time >= NTime.new(@sec, @nsec - 1))
    assert_true(@time >= NTime.new(@sec - 1, @nsec - 1))
    assert_false(@time >= NTime.new(@sec + 1, @nsec))
    assert_false(@time >= NTime.new(@sec, @nsec + 1))
    assert_false(@time >= NTime.new(@sec + 1, @nsec + 1))
    assert_true(@time >= NTime.new(@sec - 1, @nsec + 1))
    assert_false(@time >= NTime.new(@sec + 1, @nsec - 1))
    assert_true(@time >= NTime.new(@sec, @nsec))
  end

  test '>= Integer' do
    assert_true(@time >= @sec - 1)
    assert_true(@time >= @sec)
    assert_false(@time >= @sec + 1)
  end

  test '<= NTime' do
    assert_true(@time <= NTime.new(@sec + 1, @nsec))
    assert_true(@time <= NTime.new(@sec, @nsec + 1))
    assert_true(@time <= NTime.new(@sec + 1, @nsec + 1))
    assert_false(@time <= NTime.new(@sec - 1, @nsec))
    assert_false(@time <= NTime.new(@sec, @nsec - 1))
    assert_false(@time <= NTime.new(@sec - 1, @nsec - 1))
    assert_true(@time <= NTime.new(@sec + 1, @nsec - 1))
    assert_false(@time <= NTime.new(@sec - 1, @nsec + 1))
    assert_true(@time <= NTime.new(@sec, @nsec))
  end

  test '<= Integer' do
    assert_true(@time <= @sec + 1)
    assert_true(@time <= @sec)
    assert_false(@time <= @sec - 1)
  end

  test '#to_i' do
    assert_equal(@sec, @time.to_i)
  end

  test '#to_int' do
    assert_equal(@sec, @time.to_int)
  end

  test '#to_r' do
    assert_equal(Rational(@sec * 1000000000 + @nsec, 1000000000), @time.to_r)
  end
end
