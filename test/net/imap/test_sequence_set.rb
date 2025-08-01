# frozen_string_literal: true

require "net/imap"
require "test/unit"

class IMAPSequenceSetTest < Test::Unit::TestCase
  # alias for convenience
  SequenceSet     = Net::IMAP::SequenceSet
  DataFormatError = Net::IMAP::DataFormatError

  def compare_to_reference_set(nums, set, seqset)
    set.merge nums
    seqset.merge nums
    assert_equal set, seqset.to_set
    assert seqset.elements.size <= set.size
    sorted = set.to_a.sort
    assert_equal sorted, seqset.numbers
    Array.new(50) { rand(sorted.count) }.each do |idx|
      assert_equal sorted.at(idx),  seqset.at(idx)
      assert_equal sorted.at(-idx), seqset.at(-idx)
    end
    assert seqset.cover? sorted.sample 100
  end

  test "fuzz test: add numbers and compare to reference Set" do
    set    = Set.new
    seqset = SequenceSet.new
    10.times do
      nums = Array.new(1000) { rand(1..10_000) }
      compare_to_reference_set(nums, set, seqset)
    end
  end

  test "fuzz test: add ranges and compare to reference Set" do
    set    = Set.new
    seqset = SequenceSet.new
    (1..10_000).each_slice(250) do
      compare_to_reference_set _1, set, seqset
      assert_equal 1, seqset.elements.size
    end
  end

  test "fuzz test: set union identities" do
    10.times do
      lhs = SequenceSet[Array.new(100) { rand(1..300) }]
      rhs = SequenceSet[Array.new(100) { rand(1..300) }]
      union = lhs | rhs
      assert_equal union, rhs | lhs # commutative
      assert_equal union, ~(~lhs & ~rhs) # De Morgan's Law
      assert_equal union, lhs | (lhs ^ rhs)
      assert_equal union, lhs | (rhs - lhs)
      assert_equal union, (lhs & rhs) ^ (lhs ^ rhs)
      mutable = lhs.dup
      assert_equal union, mutable.merge(rhs)
      assert_equal union, mutable
    end
  end

  test "fuzz test: set intersection identities" do
    10.times do
      lhs = SequenceSet[Array.new(100) { rand(1..300) }]
      rhs = SequenceSet[Array.new(100) { rand(1..300) }]
      intersection = lhs & rhs
      assert_equal intersection, rhs & lhs # commutative
      assert_equal intersection, ~(~lhs | ~rhs) # De Morgan's Law
      assert_equal intersection, lhs - ~rhs
      assert_equal intersection, lhs - (lhs - rhs)
      assert_equal intersection, lhs - (lhs ^ rhs)
      assert_equal intersection, lhs ^ (lhs - rhs)
    end
  end

  test "fuzz test: set subtraction identities" do
    10.times do
      lhs = SequenceSet[Array.new(100) { rand(1..300) }]
      rhs = SequenceSet[Array.new(100) { rand(1..300) }]
      difference = lhs - rhs
      assert_equal difference, ~rhs - ~lhs
      assert_equal difference, ~(~lhs | rhs)
      assert_equal difference, lhs & (lhs ^ rhs)
      assert_equal difference, lhs ^ (lhs & rhs)
      assert_equal difference, rhs ^ (lhs | rhs)
      mutable = lhs.dup
      assert_equal difference, mutable.subtract(rhs)
      assert_equal difference, mutable
    end
  end

  test "fuzz test: set xor identities" do
    10.times do
      lhs = SequenceSet[Array.new(100) { rand(1..300) }]
      rhs = SequenceSet[Array.new(100) { rand(1..300) }]
      mid = SequenceSet[Array.new(100) { rand(1..300) }]
      xor = lhs ^ rhs
      assert_equal xor, rhs ^ lhs # commutative
      assert_equal xor, (lhs | rhs) - (lhs & rhs)
      assert_equal xor, (lhs ^ mid) ^ (mid ^ rhs)
      assert_equal xor, ~lhs ^ ~rhs
    end
  end

  test "fuzz test: set complement identities" do
    10.times do
      set = SequenceSet[Array.new(100) { rand(1..300) }]
      complement = ~set
      assert_equal set,        ~complement
      assert_equal complement, ~set.dup
      assert_equal complement, SequenceSet.full - set
      mutable = set.dup
      assert_equal complement, mutable.complement!
      assert_equal complement, mutable
      assert_equal set,        mutable.complement!
      assert_equal set,        mutable
    end
  end

  test "#== equality by value (not by identity or representation)" do
    assert_equal SequenceSet.new, SequenceSet.new
    assert_equal SequenceSet.new("1"), SequenceSet[1]
    assert_equal SequenceSet.new("*"), SequenceSet[:*]
    assert_equal SequenceSet["2:4"], SequenceSet["4:2"]
  end

  test "#freeze" do
    set = SequenceSet.new "2:4,7:11,99,999"
    assert !set.frozen?
    set.freeze
    assert set.frozen?
    assert Ractor.shareable?(set) if defined?(Ractor)
    assert_equal set, set.freeze
  end

  data "#clear",       :clear
  data "#replace seq", ->{ _1.replace SequenceSet[1] }
  data "#replace num", ->{ _1.replace   1 }
  data "#replace str", ->{ _1.replace  ?1 }
  data "#string=",     ->{ _1.string = ?1 }
  data "#add",         ->{ _1.add       1 }
  data "#add?",        ->{ _1.add?      1 }
  data "#<<",          ->{ _1 <<        1 }
  data "#append",      ->{ _1.append    1 }
  data "#delete",      ->{ _1.delete    3 }
  data "#delete?",     ->{ _1.delete?   3 }
  data "#delete_at",   ->{ _1.delete_at 3 }
  data "#slice!",      ->{ _1.slice!    1 }
  data "#merge",       ->{ _1.merge     1 }
  data "#subtract",    ->{ _1.subtract  1 }
  data "#limit!",      ->{ _1.limit! max: 10 }
  data "#complement!", :complement!
  data "#normalize!",  :normalize!
  test "frozen error message" do |modification|
    set = SequenceSet["2:4,7:11,99,999"]
    msg = "can't modify frozen Net::IMAP::SequenceSet: %p" % [set]
    assert_raise_with_message FrozenError, msg do
      modification.to_proc.(set)
    end
  end

  data "#min(count)",      {transform: ->{ _1.min(10)         }, }
  data "#max(count)",      {transform: ->{ _1.max(10)         }, }
  data "#slice(length)",   {transform: ->{ _1.slice(0, 10)    }, }
  data "#slice(range)",    {transform: ->{ _1.slice(0...10)   }, }
  data "#slice => empty",  {transform: ->{ _1.slice(0...0)    }, }
  data "#slice => empty",  {transform: ->{ _1.slice(10..9)    }, }
  data "#union",           {transform: ->{ _1 | (1..100)      }, }
  data "#intersection",    {transform: ->{ _1 & (1..100)      }, }
  data "#difference",      {transform: ->{ _1 - (1..100)      }, }
  data "#xor",             {transform: ->{ _1 ^ (1..100)      }, }
  data "#complement",      {transform: ->{ ~_1                }, }
  data "#normalize",       {transform: ->{ _1.normalize       }, }
  data "#above",           {transform: ->{ _1.above(22)       }, }
  data "#below",           {transform: ->{ _1.below(22)       }, }
  data "#limit",           {transform: ->{ _1.limit(max: 22)  }, freeze: :always }
  data "#limit => empty",  {transform: ->{ _1.limit(max: 1)   }, freeze: :always }
  test "transforms keep frozen status" do |data|
    data => {transform:}
    set = SequenceSet.new("2:4,7:11,99,999")
    dup = set.dup
    result = transform.to_proc.(set)
    assert_equal dup, set, "transform should not modified"
    if data in {freeze: :always}
      assert result.frozen?, "this transform always returns frozen"
    else
      refute result.frozen?, "transform of non-frozen returned frozen"
    end
    set.freeze
    result = transform.to_proc.(set)
    assert result.frozen?, "transform of frozen returned non-frozen"
  end

  %i[clone dup].each do |method|
    test "##{method}" do
      orig = SequenceSet.new "2:4,7:11,99,999"
      copy = orig.send method
      assert_equal orig, copy
      orig << 123
      copy << 456
      assert_not_equal orig, copy
      assert  orig.include?(123)
      assert  copy.include?(456)
      assert !copy.include?(123)
      assert !orig.include?(456)
    end
  end

  if defined?(Ractor)
    test "#freeze makes ractor sharable (deeply frozen)" do
      assert Ractor.shareable? SequenceSet.new("1:9,99,999").freeze
    end

    test ".[] returns ractor sharable (deeply frozen)" do
      assert Ractor.shareable? SequenceSet["2:8,88,888"]
    end

    test "#clone preserves ractor sharability (deeply frozen)" do
      assert Ractor.shareable? SequenceSet["3:7,77,777"].clone
    end
  end

  test ".new, input must be valid" do
    assert_raise DataFormatError do SequenceSet.new [0]          end
    assert_raise DataFormatError do SequenceSet.new "0"          end
    assert_raise DataFormatError do SequenceSet.new [2**32]      end
    assert_raise DataFormatError do SequenceSet.new [2**33]      end
    assert_raise DataFormatError do SequenceSet.new (2**32).to_s end
    assert_raise DataFormatError do SequenceSet.new (2**33).to_s end
    assert_raise DataFormatError do SequenceSet.new "0:2"        end
    assert_raise DataFormatError do SequenceSet.new ":2"         end
    assert_raise DataFormatError do SequenceSet.new " 2"         end
    assert_raise DataFormatError do SequenceSet.new "2 "         end
    assert_raise DataFormatError do SequenceSet.new "2,"         end
    assert_raise DataFormatError do SequenceSet.new Time.now     end
    assert_raise DataFormatError do SequenceSet.new Set[1, [2]]  end
    assert_raise DataFormatError do SequenceSet.new Set[1..20]   end
  end

  test ".[frozen SequenceSet] returns that SequenceSet" do
    frozen_seqset = SequenceSet[123..456]
    assert_same frozen_seqset, SequenceSet[frozen_seqset]

    coercible = Object.new
    frozen_seqset = SequenceSet[192, 168, 1, 255]
    coercible.define_singleton_method(:to_sequence_set) { frozen_seqset }
    assert_same frozen_seqset, SequenceSet[coercible]

    coercible = Object.new
    mutable_seqset = SequenceSet.new([192, 168, 1, 255])
    coercible.define_singleton_method(:to_sequence_set) { mutable_seqset }
    assert_equal mutable_seqset, SequenceSet[coercible]
    refute_same  mutable_seqset, SequenceSet[coercible]
  end

  test ".new, input may be empty" do
    assert_empty SequenceSet.new
    assert_empty SequenceSet.new []
    assert_empty SequenceSet.new [[]]
    assert_empty SequenceSet.new nil
    assert_empty SequenceSet.new ""
    assert_empty SequenceSet.new Set.new
  end

  test ".[] must not be empty" do
    assert_raise ArgumentError   do SequenceSet[]     end
    assert_raise DataFormatError do SequenceSet[[]]   end
    assert_raise DataFormatError do SequenceSet[[[]]] end
    assert_raise DataFormatError do SequenceSet[nil]  end
    assert_raise DataFormatError do SequenceSet[""]   end
    assert_raise DataFormatError do SequenceSet[Set.new] end
  end

  test ".try_convert" do
    assert_nil SequenceSet.try_convert(nil)
    assert_nil SequenceSet.try_convert(123)
    assert_nil SequenceSet.try_convert(12..34)
    assert_nil SequenceSet.try_convert("12:34")
    assert_nil SequenceSet.try_convert(Object.new)

    obj = Object.new
    def obj.to_sequence_set; SequenceSet[192, 168, 1, 255] end
    assert_equal SequenceSet[192, 168, 1, 255], SequenceSet.try_convert(obj)

    obj = Object.new
    def obj.to_sequence_set; 192_168.001_255 end
    assert_raise DataFormatError do SequenceSet.try_convert(obj) end
  end

  test "Net::IMAP::SequenceSet(set)" do
    assert_equal SequenceSet.empty,   Net::IMAP::SequenceSet()
    assert_equal SequenceSet.empty,   Net::IMAP::SequenceSet(nil)
    assert_equal SequenceSet.empty,   Net::IMAP::SequenceSet([])
    assert_equal SequenceSet.empty,   Net::IMAP::SequenceSet([[]])
    assert_equal SequenceSet.empty,   Net::IMAP::SequenceSet("")
    assert_equal SequenceSet[123],    Net::IMAP::SequenceSet(123)
    assert_equal SequenceSet[12..34], Net::IMAP::SequenceSet(12..34)
    assert_equal SequenceSet[12..34], Net::IMAP::SequenceSet("12:34")

    refute Net::IMAP::SequenceSet("").frozen?

    assert_raise DataFormatError do Net::IMAP::SequenceSet(Object.new) end

    set = SequenceSet[123]
    assert_same set, Net::IMAP::SequenceSet(set)

    set = SequenceSet.new(123)
    assert_same set, Net::IMAP::SequenceSet(set)

    obj = Object.new
    set = SequenceSet[192, 168, 1, 255]
    obj.define_singleton_method(:to_sequence_set) { set }
    assert_same set, Net::IMAP::SequenceSet(obj)

    obj = Object.new
    def obj.to_sequence_set; 192_168.001_255 end
    assert_raise DataFormatError do Net::IMAP::SequenceSet(obj) end
  end

  test "#at(non-negative index)" do
    assert_nil        SequenceSet.empty.at(0)
    assert_equal   1, SequenceSet[1..].at(0)
    assert_equal   1, SequenceSet.full.at(0)
    assert_equal 111, SequenceSet.full.at(110)
    assert_equal   4, SequenceSet[2,4,6,8].at(1)
    assert_equal   8, SequenceSet[2,4,6,8].at(3)
    assert_equal   6, SequenceSet[4..6].at(2)
    assert_nil        SequenceSet[4..6].at(3)
    assert_equal 205, SequenceSet["101:110,201:210,301:310"].at(14)
    assert_equal 310, SequenceSet["101:110,201:210,301:310"].at(29)
    assert_nil        SequenceSet["101:110,201:210,301:310"].at(44)
    assert_equal  :*, SequenceSet["1:10,*"].at(10)
  end

  test "#[non-negative index]" do
    assert_nil        SequenceSet.empty[0]
    assert_equal   1, SequenceSet[1..][0]
    assert_equal   1, SequenceSet.full[0]
    assert_equal 111, SequenceSet.full[110]
    assert_equal   4, SequenceSet[2,4,6,8][1]
    assert_equal   8, SequenceSet[2,4,6,8][3]
    assert_equal   6, SequenceSet[4..6][2]
    assert_nil        SequenceSet[4..6][3]
    assert_equal 205, SequenceSet["101:110,201:210,301:310"][14]
    assert_equal 310, SequenceSet["101:110,201:210,301:310"][29]
    assert_nil        SequenceSet["101:110,201:210,301:310"][44]
    assert_equal  :*, SequenceSet["1:10,*"][10]
  end

  test "#at(negative index)" do
    assert_nil        SequenceSet.empty.at(-1)
    assert_equal  :*, SequenceSet[1..].at(-1)
    assert_equal   1, SequenceSet.full.at(-(2**32))
    assert_equal 111, SequenceSet[1..111].at(-1)
    assert_equal   6, SequenceSet[2,4,6,8].at(-2)
    assert_equal   2, SequenceSet[2,4,6,8].at(-4)
    assert_equal   4, SequenceSet[4..6].at(-3)
    assert_nil        SequenceSet[4..6].at(-4)
    assert_equal 207, SequenceSet["101:110,201:210,301:310"].at(-14)
    assert_equal 102, SequenceSet["101:110,201:210,301:310"].at(-29)
    assert_nil        SequenceSet["101:110,201:210,301:310"].at(-44)
  end

  test "#[negative index]" do
    assert_nil        SequenceSet.empty[-1]
    assert_equal  :*, SequenceSet[1..][-1]
    assert_equal   1, SequenceSet.full[-(2**32)]
    assert_equal 111, SequenceSet[1..111][-1]
    assert_equal   6, SequenceSet[2,4,6,8][-2]
    assert_equal   2, SequenceSet[2,4,6,8][-4]
    assert_equal   4, SequenceSet[4..6][-3]
    assert_nil        SequenceSet[4..6][-4]
    assert_equal 207, SequenceSet["101:110,201:210,301:310"][-14]
    assert_equal 102, SequenceSet["101:110,201:210,301:310"][-29]
    assert_nil        SequenceSet["101:110,201:210,301:310"][-44]
  end

  test "#ordered_at(non-negative index)" do
    assert_nil        SequenceSet.empty.ordered_at(0)
    assert_equal   1, SequenceSet.full.ordered_at(0)
    assert_equal 111, SequenceSet.full.ordered_at(110)
    assert_equal   1, SequenceSet["1:*"].ordered_at(0)
    assert_equal  :*, SequenceSet["*,1"].ordered_at(0)
    assert_equal   4, SequenceSet["6,4,8,2"].ordered_at(1)
    assert_equal   2, SequenceSet["6,4,8,2"].ordered_at(3)
    assert_equal   6, SequenceSet["9:11,4:6,1:3"].ordered_at(5)
    assert_nil        SequenceSet["9:11,4:6,1:3"].ordered_at(9)
    assert_equal 105, SequenceSet["201:210,101:110,301:310"].ordered_at(14)
    assert_equal 310, SequenceSet["201:210,101:110,301:310"].ordered_at(29)
    assert_nil        SequenceSet["201:210,101:110,301:310"].ordered_at(30)
    assert_equal  :*, SequenceSet["1:10,*"].ordered_at(10)
  end

  test "#ordered_at(negative index)" do
    assert_nil        SequenceSet.empty.ordered_at(-1)
    assert_equal  :*, SequenceSet["1:*"].ordered_at(-1)
    assert_equal   1, SequenceSet.full.ordered_at(-(2**32))
    assert_equal  :*, SequenceSet["*,1"].ordered_at(0)
    assert_equal   8, SequenceSet["6,4,8,2"].ordered_at(-2)
    assert_equal   6, SequenceSet["6,4,8,2"].ordered_at(-4)
    assert_equal   4, SequenceSet["9:11,4:6,1:3"].ordered_at(-6)
    assert_equal  10, SequenceSet["9:11,4:6,1:3"].ordered_at(-8)
    assert_nil        SequenceSet["9:11,4:6,1:3"].ordered_at(-12)
    assert_equal 107, SequenceSet["201:210,101:110,301:310"].ordered_at(-14)
    assert_equal 201, SequenceSet["201:210,101:110,301:310"].ordered_at(-30)
    assert_nil        SequenceSet["201:210,101:110,301:310"].ordered_at(-31)
    assert_equal  :*, SequenceSet["1:10,*"].ordered_at(10)
  end

  test "#[start, length]" do
    assert_equal SequenceSet[10..99], SequenceSet.full[9, 90]
    assert_equal 90, SequenceSet.full[9, 90].count
    assert_equal SequenceSet[1000..1099],
                 SequenceSet[1..100, 1000..1111][100, 100]
    assert_equal SequenceSet[11, 21, 31, 41],
                 SequenceSet[((1..10_000) % 10).to_a][1, 4]
    assert_equal SequenceSet[9981, 9971, 9961, 9951],
                 SequenceSet[((1..10_000) % 10).to_a][-5, 4]
    assert_nil SequenceSet[111..222, 888..999][2000, 4]
    assert_nil SequenceSet[111..222, 888..999][-2000, 4]
    # with length longer than the remaining members
    assert_equal SequenceSet[101...200],
                 SequenceSet[1...200][100, 10000]
  end

  test "#[range]" do
    assert_equal SequenceSet[10..100], SequenceSet.full[9..99]
    assert_equal SequenceSet[1000..1100],
                 SequenceSet[1..100, 1000..1111][100..200]
    assert_equal SequenceSet[1000..1099],
                 SequenceSet[1..100, 1000..1111][100...200]
    assert_equal SequenceSet[11, 21, 31, 41],
                 SequenceSet[((1..10_000) % 10).to_a][1..4]
    assert_equal SequenceSet[9981, 9971, 9961, 9951],
                 SequenceSet[((1..10_000) % 10).to_a][-5..-2]
    assert_equal SequenceSet[((51..9951) % 10).to_a],
                 SequenceSet[((1..10_000) % 10).to_a][5..-5]
    assert_equal SequenceSet.full, SequenceSet.full[0..]
    assert_equal SequenceSet[2..], SequenceSet.full[1..]
    assert_equal SequenceSet[:*], SequenceSet.full[-1..]
    assert_equal SequenceSet.empty, SequenceSet[1..100][60..50]
    assert_equal SequenceSet.empty, SequenceSet[1..100][-50..-60]
    assert_equal SequenceSet.empty, SequenceSet[1..100][-10..10]
    assert_equal SequenceSet.empty, SequenceSet[1..100][60..-60]
    assert_equal SequenceSet.empty, SequenceSet[1..100][10...0]
    assert_equal SequenceSet.empty, SequenceSet[1..100][0...0]
    assert_nil SequenceSet.empty[2..4]
    assert_nil SequenceSet[101..200][1000..1060]
    assert_nil SequenceSet[101..200][-1000..-60]
    # with length longer than the remaining members
    assert_equal SequenceSet[101..1111], SequenceSet[1..1111][100..999_999]
  end

  test "#find_index" do
    assert_equal   9, SequenceSet.full.find_index(10)
    assert_equal  99, SequenceSet.full.find_index(100)
    set = SequenceSet[1..100, 1000..1111]
    assert_equal 100, set.find_index(1000)
    assert_equal 200, set.find_index(1100)
    set = SequenceSet[((1..10_000) % 10).to_a]
    assert_equal   0, set.find_index(1)
    assert_equal   1, set.find_index(11)
    assert_equal   5, set.find_index(51)
    assert_nil SequenceSet.empty.find_index(1)
    assert_nil SequenceSet[5..9].find_index(4)
    assert_nil SequenceSet[5..9,12..24].find_index(10)
    assert_nil SequenceSet[5..9,12..24].find_index(11)
    assert_equal         1, SequenceSet[1, :*].find_index(-1)
    assert_equal 2**32 - 1, SequenceSet.full.find_index(:*)
  end

  test "#find_ordered_index" do
    assert_equal         9, SequenceSet.full.find_ordered_index(10)
    assert_equal        99, SequenceSet.full.find_ordered_index(100)
    assert_equal 2**32 - 1, SequenceSet.full.find_ordered_index(:*)
    assert_nil SequenceSet.empty.find_index(1)
    set = SequenceSet["9,8,7,6,5,4,3,2,1"]
    assert_equal 0, set.find_ordered_index(9)
    assert_equal 1, set.find_ordered_index(8)
    assert_equal 2, set.find_ordered_index(7)
    assert_equal 3, set.find_ordered_index(6)
    assert_equal 4, set.find_ordered_index(5)
    assert_equal 5, set.find_ordered_index(4)
    assert_equal 6, set.find_ordered_index(3)
    assert_equal 7, set.find_ordered_index(2)
    assert_equal 8, set.find_ordered_index(1)
    assert_nil      set.find_ordered_index(10)
    set = SequenceSet["7:9,5:6"]
    assert_equal 0, set.find_ordered_index(7)
    assert_equal 1, set.find_ordered_index(8)
    assert_equal 2, set.find_ordered_index(9)
    assert_equal 3, set.find_ordered_index(5)
    assert_equal 4, set.find_ordered_index(6)
    assert_nil   set.find_ordered_index(4)
    set = SequenceSet["1000:1111,1:100"]
    assert_equal   0, set.find_ordered_index(1000)
    assert_equal 100, set.find_ordered_index(1100)
    assert_equal 112, set.find_ordered_index(1)
    assert_equal 121, set.find_ordered_index(10)
    set = SequenceSet["1,1,1,1,51,50,4,11"]
    assert_equal   0, set.find_ordered_index(1)
    assert_equal   4, set.find_ordered_index(51)
    assert_equal   5, set.find_ordered_index(50)
    assert_equal   6, set.find_ordered_index(4)
    assert_equal   7, set.find_ordered_index(11)
    assert_equal   1, SequenceSet["1,*"].find_ordered_index(-1)
    assert_equal   0, SequenceSet["*,1"].find_ordered_index(-1)
  end

  test "#above" do
    set = SequenceSet["5,10:22,50"]
    assert_equal SequenceSet.empty,         set.above(2**32 - 1)
    assert_equal SequenceSet.empty,         set.above(99)
    assert_equal SequenceSet.empty,         set.above(50)
    assert_equal SequenceSet["50"],         set.above(40)
    assert_equal SequenceSet["50"],         set.above(30)
    assert_equal SequenceSet["21:22,50"],   set.above(20)
    assert_equal SequenceSet["11:22,50"],   set.above(10)
    assert_equal SequenceSet["5,10:22,50"], set.above(1)
    assert_raise ArgumentError do           set.above(2**32) end
    assert_raise ArgumentError do           set.above(0)     end
    assert_raise ArgumentError do           set.above(-1)    end
    assert_raise ArgumentError do           set.above(:*)    end
  end

  test "#below" do
    set = SequenceSet["5,10:22,50"]
    assert_equal SequenceSet["5,10:22,50"], set.below(99)
    assert_equal SequenceSet["5,10:22"],    set.below(50)
    assert_equal SequenceSet["5,10:22"],    set.below(40)
    assert_equal SequenceSet["5,10:22"],    set.below(30)
    assert_equal SequenceSet["5,10:19"],    set.below(20)
    assert_equal SequenceSet["5"],          set.below(10)
    assert_equal SequenceSet.empty,         set.below(1)
    assert_equal SequenceSet.empty,         set.below(1)
    assert_raise ArgumentError do           set.below(2**32) end
    assert_raise ArgumentError do           set.below(0)     end
    assert_raise ArgumentError do           set.below(-1)    end
    assert_raise ArgumentError do           set.below(:*)    end
  end

  test "#limit" do
    set = SequenceSet["1:100,500"]
    assert_equal [1..99],               set.limit(max: 99).ranges
    assert_equal (1..15).to_a,          set.limit(max: 15).numbers
    assert_equal SequenceSet["1:100"],  set.limit(max: 101)
    assert_equal SequenceSet["1:97"],   set.limit(max: 97)
    assert_equal [1..99],               set.limit(max: 99).ranges
    assert_equal (1..15).to_a,          set.limit(max: 15).numbers
  end

  test "#limit with *" do
    assert_equal SequenceSet.new("2,4,5,6,7,9,12,13,14,15"),
                 SequenceSet.new("2,4:7,9,12:*").limit(max: 15)
    assert_equal(SequenceSet["37"],
                 SequenceSet["50,60,99:*"].limit(max: 37))
    assert_equal(SequenceSet["1:100,300"],
                 SequenceSet["1:100,500:*"].limit(max: 300))
    assert_equal [15], SequenceSet["3967:*"].limit(max: 15).numbers
    assert_equal [15], SequenceSet["*:12293456"].limit(max: 15).numbers
  end

  test "#limit with empty result" do
    assert_equal SequenceSet.empty, SequenceSet["1234567890"].limit(max: 37)
    assert_equal SequenceSet.empty, SequenceSet["99:195,458"].limit(max: 37)
  end

  test "values for '*'" do
    assert_equal "*",   SequenceSet[?*].to_s
    assert_equal "*",   SequenceSet[:*].to_s
    assert_equal "*",   SequenceSet[-1].to_s
    assert_equal "*",   SequenceSet[[?*]].to_s
    assert_equal "*",   SequenceSet[[:*]].to_s
    assert_equal "*",   SequenceSet[[-1]].to_s
    assert_equal "1:*", SequenceSet[1..].to_s
    assert_equal "1:*", SequenceSet[1..-1].to_s
  end

  test "#empty?" do
    refute SequenceSet.new("1:*").empty?
    refute SequenceSet.new(:*).empty?
    assert SequenceSet.new(nil).empty?
    assert SequenceSet.new.empty?
    assert SequenceSet.empty.empty?
    set = SequenceSet.new "1:1111"
    refute set.empty?
    set.string = nil
    assert set.empty?
  end

  test "#full?" do
    assert SequenceSet.new("1:*").full?
    refute SequenceSet.new(1..2**32-1).full?
    refute SequenceSet.new(nil).full?
  end

  test "#to_sequence_set" do
    assert_equal (set = SequenceSet["*"]),              set.to_sequence_set
    assert_equal (set = SequenceSet["15:36,5,99,*,2"]), set.to_sequence_set
  end

  test "set + other" do
    seqset = -> { SequenceSet.new _1 }
    assert_equal seqset["1,5"],       seqset["1"]         + seqset["5"]
    assert_equal seqset["1,*"],       seqset["*"]         + seqset["1"]
    assert_equal seqset["1:*"],       seqset["1:4"]       + seqset["5:*"]
    assert_equal seqset["1:*"],       seqset["5:*"]       + seqset["1:4"]
    assert_equal seqset["1:5"],       seqset["1,3,5"]     + seqset["2,4"]
    assert_equal seqset["1:3,5,7:9"], seqset["1,3,5,7:8"] + seqset["2,8:9"]
    assert_equal seqset["1:*"],       seqset["1,3,5,7:*"] + seqset["2,4:6"]
  end

  test "#add" do
    assert_equal SequenceSet["1,5"], SequenceSet.new("1").add("5")
    assert_equal SequenceSet["1,*"], SequenceSet.new("*").add(1)
    assert_equal SequenceSet["1:9"], SequenceSet.new("1:6").add("4:9")
    assert_equal SequenceSet["1:*"], SequenceSet.new("1:4").add(5..)
    assert_equal SequenceSet["1:*"], SequenceSet.new("5:*").add(1..4)
  end

  test "#<<" do
    assert_equal SequenceSet["1,5"], SequenceSet.new("1")   << "5"
    assert_equal SequenceSet["1,*"], SequenceSet.new("*")   << 1
    assert_equal SequenceSet["1:9"], SequenceSet.new("1:6") << "4:9"
    assert_equal SequenceSet["1:*"], SequenceSet.new("1:4") << (5..)
    assert_equal SequenceSet["1:*"], SequenceSet.new("5:*") << (1..4)
  end

  test "#append" do
    assert_equal "1,5",     SequenceSet.new("1").append("5").string
    assert_equal "*,1",     SequenceSet.new("*").append(1).string
    assert_equal "1:6,4:9", SequenceSet.new("1:6").append("4:9").string
    assert_equal "1:4,5:*", SequenceSet.new("1:4").append(5..).string
    assert_equal "5:*,1:4", SequenceSet.new("5:*").append(1..4).string
    # also works from empty
    assert_equal "5,1",     SequenceSet.new.append(5).append(1).string
    # also works when *previously* input was non-strings
    assert_equal "*,1",     SequenceSet.new(:*).append(1).string
    assert_equal "1,5",     SequenceSet.new(1).append("5").string
    assert_equal "1:6,4:9", SequenceSet.new(1..6).append(4..9).string
    assert_equal "1:4,5:*", SequenceSet.new(1..4).append(5..).string
    assert_equal "5:*,1:4", SequenceSet.new(5..).append(1..4).string
  end

  test "#merge" do
    seqset = -> { SequenceSet.new _1 }
    assert_equal seqset["1,5"],       seqset["1"].merge("5")
    assert_equal seqset["1,*"],       seqset["*"].merge(1)
    assert_equal seqset["1:*"],       seqset["1:4"].merge(5..)
    assert_equal seqset["1:3,5,7:9"], seqset["1,3,5,7:8"].merge(seqset["2,8:9"])
    assert_equal seqset["1:*"],       seqset["5:*"].merge(1..4)
    assert_equal seqset["1:5"],       seqset["1,3,5"].merge(seqset["2,4"])
    # when merging frozen SequenceSet
    set = SequenceSet.new
    set.merge SequenceSet[1, 3, 5]
    set.merge SequenceSet[2..33]
    assert_equal seqset[1..33], set
  end

  test "set - other" do
    seqset = -> { SequenceSet.new _1 }
    assert_equal seqset["1,5"],       seqset["1,5"] - 9
    assert_equal seqset["1,5"],       seqset["1,5"] - "3"
    assert_equal seqset["1,5"],       seqset["1,3,5"] - [3]
    assert_equal seqset["1,9"],       seqset["1,3:9"] - "2:8"
    assert_equal seqset["1,9"],       seqset["1:7,9"] - (2..8)
    assert_equal seqset["1,9"],       seqset["1:9"] - (2..8).to_a
    assert_equal seqset["1,5"],       seqset["1,5:9,11:99"] - "6:999"
    assert_equal seqset["1,5,99"],    seqset["1,5:9,11:88,99"] - ["6:98"]
    assert_equal seqset["1,5,99"],    seqset["1,5:6,8:9,11:99"] - "6:98"
    assert_equal seqset["1,5,11:99"], seqset["1,5:6,8:9,11:99"] - "6:9"
    assert_equal seqset["1:10"],      seqset["1:*"] - (11..)
    assert_equal seqset[nil],         seqset["1,5"] - [1..8, 10..]
  end

  test "#intersection" do
    seqset = -> { SequenceSet.new _1 }
    assert_equal seqset[nil],         seqset["1,5"] & "9"
    assert_equal seqset["1,5"],       seqset["1:5"].intersection([1, 5..9])
    assert_equal seqset["1,5"],       seqset["1:5"] & [1, 5, 9, 55]
    assert_equal seqset["*"],         seqset["9999:*"] & "1,5,9,*"
  end

  test "#intersect?" do
    set = SequenceSet["1:5,11:20"]
    refute set.intersect? "9"
    refute set.intersect? 9
    refute set.intersect? 6..10
    refute set.intersect? ~set
    assert set.intersect? 6..11
    assert set.intersect? "1,5,11,20"
    assert set.intersect? set
  end

  test "#disjoint?" do
    set = SequenceSet["1:5,11:20"]
    assert set.disjoint? "9"
    assert set.disjoint? 6..10
    assert set.disjoint? ~set
    refute set.disjoint? 6..11
    refute set.disjoint? "1,5,11,20"
    refute set.disjoint? set
  end

  test "#delete" do
    seqset = -> { SequenceSet.new _1 }
    assert_equal seqset["1,5"],       seqset["1,5"].delete("9")
    assert_equal seqset["1,5"],       seqset["1,5"].delete("3")
    assert_equal seqset["1,5"],       seqset["1,3,5"].delete("3")
    assert_equal seqset["1,9"],       seqset["1,3:9"].delete("2:8")
    assert_equal seqset["1,9"],       seqset["1:7,9"].delete("2:8")
    assert_equal seqset["1,9"],       seqset["1:9"].delete("2:8")
    assert_equal seqset["1,5"],       seqset["1,5:9,11:99"].delete("6:999")
    assert_equal seqset["1,5,99"],    seqset["1,5:9,11:88,99"].delete("6:98")
    assert_equal seqset["1,5,99"],    seqset["1,5:6,8:9,11:99"].delete("6:98")
    assert_equal seqset["1,5,11:99"], seqset["1,5:6,8:9,11:99"].delete("6:9")
  end

  test "#subtract" do
    seqset = -> { SequenceSet.new _1 }
    assert_equal seqset["1,5"],       seqset["1,5"].subtract("9")
    assert_equal seqset["1,5"],       seqset["1,5"].subtract("3")
    assert_equal seqset["1,5"],       seqset["1,3,5"].subtract("3")
    assert_equal seqset["1,9"],       seqset["1,3:9"].subtract("2:8")
    assert_equal seqset["1,9"],       seqset["1:7,9"].subtract("2:8")
    assert_equal seqset["1,9"],       seqset["1:9"].subtract("2:8")
    assert_equal seqset["1,5"],       seqset["1,5:9,11:99"].subtract("6:999")
    assert_equal seqset["1,5,99"],    seqset["1,5:9,11:88,99"].subtract("6:98")
    assert_equal seqset["1,5,99"],    seqset["1,5:6,8:9,11:99"].subtract("6:98")
    assert_equal seqset["1,5,11:99"], seqset["1,5:6,8:9,11:99"].subtract("6:9")
  end

  test "#xor" do
    seqset = -> { SequenceSet.new(_1) }
    assert_equal seqset["1:5,11:15"], seqset["1:10"] ^ seqset["6:15"]
    assert_equal seqset["1,3,5:6"],   seqset[1..5]   ^ [2, 4, 6]
    assert_equal SequenceSet.empty,   seqset[1..5]   ^ seqset[1..5]
    assert_equal seqset["1:100"],     seqset["1:50"] ^ seqset["51:100"]
    assert_equal seqset["1:50"],      seqset["1:50"] ^ SequenceSet.empty
    assert_equal seqset["1:50"],      SequenceSet.empty ^ seqset["1:50"]
  end

  test "#min" do
    assert_equal   3, SequenceSet.new("34:3").min
    assert_equal 345, SequenceSet.new("345,678").min
    assert_nil        SequenceSet.new.min
    # with a count
    assert_equal SequenceSet["3:6"],     SequenceSet["34:3"].min(4)
    assert_equal SequenceSet["345"],     SequenceSet["345,678"].min(1)
    assert_equal SequenceSet["345,678"], SequenceSet["345,678"].min(222)
    assert_equal SequenceSet.empty,      SequenceSet.new.min(5)
  end

  test "#max" do
    assert_equal  34, SequenceSet["34:3"].max
    assert_equal 678, SequenceSet["345,678"].max
    assert_equal 678, SequenceSet["345:678"].max(star: "unused")
    assert_equal  :*, SequenceSet["345:*"].max
    assert_equal nil, SequenceSet["345:*"].max(star: nil)
    assert_equal "*", SequenceSet["345:*"].max(star: "*")
    assert_nil SequenceSet.new.max(star: "ignored")
    # with a count
    assert_equal SequenceSet["31:34"],   SequenceSet["34:3"].max(4)
    assert_equal SequenceSet["678"],     SequenceSet["345,678"].max(1)
    assert_equal SequenceSet["345,678"], SequenceSet["345,678"].max(222)
    assert_equal SequenceSet.empty,      SequenceSet.new.max(5)
  end

  test "#minmax" do
    assert_equal [  3,   3], SequenceSet["3"].minmax
    assert_equal [ :*,  :*], SequenceSet["*"].minmax
    assert_equal [ 99,  99], SequenceSet["*"].minmax(star: 99)
    assert_equal [  3,  34], SequenceSet["34:3"].minmax
    assert_equal [345, 678], SequenceSet["345,678"].minmax
    assert_equal [345, 678], SequenceSet["345:678"].minmax(star: "unused")
    assert_equal [345,  :*], SequenceSet["345:*"].minmax
    assert_equal [345, nil], SequenceSet["345:*"].minmax(star: nil)
    assert_equal [345, "*"], SequenceSet["345:*"].minmax(star: "*")
    assert_nil SequenceSet.new.minmax(star: "ignored")
  end

  test "#add?" do
    assert_equal(SequenceSet.new("1:3,5,7:8"),
                 SequenceSet.new("1,3,5,7:8").add?("2"))
    assert_equal(SequenceSet.new("1,3,5,7:9"),
                 SequenceSet.new("1,3,5,7:8").add?("8:9"))
    assert_nil   SequenceSet.new("1,3,5,7:*").add?("3")
    assert_nil   SequenceSet.new("1,3,5,7:*").add?("9:91")
  end

  test "#delete?" do
    set = SequenceSet.new [5..10, 20]
    assert_nil   set.delete?(11)
    assert_equal SequenceSet[5..10, 20], set
    assert_equal 6, set.delete?(6)
    assert_equal SequenceSet[5, 7..10, 20], set
    assert_equal SequenceSet[9..10, 20],    set.delete?(9..)
    assert_equal SequenceSet[5, 7..8],      set
    assert_nil   set.delete?(11..)
  end

  test "#slice!" do
    set = SequenceSet.new 1..20
    assert_equal SequenceSet[1..4], set.slice!(0, 4)
    assert_equal SequenceSet[5..20], set
    assert_equal 14, set.slice!(-7)
    assert_equal SequenceSet[5..13, 15..20], set
    assert_equal 11, set.slice!(6)
    assert_equal SequenceSet[5..10, 12..13, 15..20], set
    assert_equal SequenceSet[12..13, 15..19], set.slice!(6..12)
    assert_equal SequenceSet[5..10, 20], set
    assert_nil   set.slice!(10)
    assert_equal SequenceSet[5..10, 20], set
    assert_equal 6, set.slice!(1)
    assert_equal SequenceSet[5, 7..10, 20], set
    assert_equal SequenceSet[9..10, 20],    set.slice!(3..)
    assert_equal SequenceSet[5, 7..8],      set
    assert_nil   set.slice!(3)
    assert_nil   set.slice!(3..)
  end

  test "#delete_at" do
    set = SequenceSet.new [5..10, 20]
    assert_nil   set.delete_at(20)
    assert_equal SequenceSet[5..10, 20], set
    assert_equal   6, set.delete_at(1)
    assert_equal   9, set.delete_at(3)
    assert_equal  10, set.delete_at(3)
    assert_equal  20, set.delete_at(3)
    assert_equal nil, set.delete_at(3)
    assert_equal SequenceSet[5, 7..8], set
  end

  test "#include_star?" do
    assert SequenceSet["2,*:12"].include_star?
    assert SequenceSet[-1].include_star?
    refute SequenceSet["12"].include_star?
  end

  test "#include?" do
    assert_equal true, SequenceSet["2:4"].include?(3)
    assert_equal true, SequenceSet["2,*:12"].include?(:*)
    assert_equal true, SequenceSet["2,*:12"].include?(-1)
    assert_nil SequenceSet["1:*"].include?("hopes and dreams")
    assert_nil SequenceSet["1:*"].include?(:wat?)
    assert_nil SequenceSet["1:*"].include?([1, 2, 3])
    set = SequenceSet.new Array.new(100) { rand(1..1500) }
    rev = (~set).limit(max: 1_501)
    set.numbers.each do assert_equal true,  set.include?(_1) end
    rev.numbers.each do assert_equal false, set.include?(_1) end
  end

  test "#cover?" do
    assert SequenceSet["2:4"].cover?(3)
    assert SequenceSet["2,4:7,9,12:*"] === 2
    assert SequenceSet["2,4:7,9,12:*"].cover?(2222)
    assert SequenceSet["2,*:12"].cover? :*
    assert SequenceSet["2,*:12"].cover?(-1)
    assert SequenceSet["2,*:12"].cover?(99..5000)
    refute SequenceSet["2,*:12"].cover?(10)
    refute SequenceSet["2,*:12"].cover?(10..13)
    assert SequenceSet["2:12"].cover?(10..12)
    refute SequenceSet["2:12"].cover?(10..13)
    assert SequenceSet["2:12"].cover?(10...13)
    set = SequenceSet.new Array.new(100) { rand(1..1500) }
    rev = (~set).limit(max: 1_501)
    refute set.cover?(rev)
    set.each_element do assert set.cover?(_1) end
    rev.each_element do refute set.cover?(_1) end
    assert SequenceSet["2:4"].cover? []
    assert SequenceSet["2:4"].cover? SequenceSet.empty
    assert SequenceSet["2:4"].cover? nil
    assert SequenceSet["2:4"].cover? ""
    refute SequenceSet["2:4"].cover? "*"
    refute SequenceSet["2:4"].cover? SequenceSet.full
    assert SequenceSet.full  .cover? SequenceSet.full
    assert SequenceSet.full  .cover? :*
    assert SequenceSet.full  .cover?(-1)
    assert SequenceSet.empty .cover? SequenceSet.empty
    refute SequenceSet.empty .cover? SequenceSet[:*]
  end

  test "~full == empty" do
    assert_equal SequenceSet.new("1:*"), ~SequenceSet.new
    assert_equal SequenceSet.new,        ~SequenceSet.new("1:*")
    assert_equal SequenceSet.new("1:*"),  SequenceSet.new       .complement
    assert_equal SequenceSet.new,         SequenceSet.new("1:*").complement
    assert_equal SequenceSet.new("1:*"),  SequenceSet.new       .complement!
    assert_equal SequenceSet.new,         SequenceSet.new("1:*").complement!
  end

  data(
    # desc         => [expected, input, freeze]
    "empty"        => ["Net::IMAP::SequenceSet()",          nil],
    "frozen empty" => ["Net::IMAP::SequenceSet.empty",      nil, true],
    "normalized"   => ['Net::IMAP::SequenceSet("1:2")',   [2, 1]],
    "denormalized" => ['Net::IMAP::SequenceSet("2,1")',   "2,1"],
    "star"         => ['Net::IMAP::SequenceSet("*")',     "*"],
    "frozen"       => ['Net::IMAP::SequenceSet["1,3,5:*"]', [1, 3, 5..], true],
  )
  def test_inspect((expected, input, freeze))
    seqset = SequenceSet.new(input)
    seqset = seqset.freeze if freeze
    assert_equal expected, seqset.inspect
  end

  data "single number", {
    input:      "123456",
    elements:   [123_456],
    entries:    [123_456],
    ranges:     [123_456..123_456],
    numbers:    [123_456],
    to_s:       "123456",
    normalize:  "123456",
    count:      1,
    complement: "1:123455,123457:*",
  }, keep: true

  data "single range", {
    input:      "1:3",
    elements:   [1..3],
    entries:    [1..3],
    ranges:     [1..3],
    numbers:    [1, 2, 3],
    to_s:       "1:3",
    normalize:  "1:3",
    count:      3,
    complement: "4:*",
  }, keep: true

  data "simple numbers list", {
    input:      "1,3,5",
    elements:   [   1,    3,    5],
    entries:    [   1,    3,    5],
    ranges:     [1..1, 3..3, 5..5],
    numbers:    [   1,    3,    5],
    to_s:       "1,3,5",
    normalize:  "1,3,5",
    count:      3,
    complement: "2,4,6:*",
  }, keep: true

  data "numbers and ranges list", {
    input:      "1:3,5,7:9,46",
    elements:   [1..3,    5, 7..9,     46],
    entries:    [1..3,    5, 7..9,     46],
    ranges:     [1..3, 5..5, 7..9, 46..46],
    numbers:    [1, 2, 3, 5, 7, 8, 9,  46],
    to_s:       "1:3,5,7:9,46",
    normalize:  "1:3,5,7:9,46",
    count:      8,
    complement: "4,6,10:45,47:*",
  }, keep: true

  data "just *", {
    input:      "*",
    elements:   [:*],
    entries:    [:*],
    ranges:     [:*..],
    numbers:    RangeError,
    to_s:       "*",
    normalize:  "*",
    count:      1,
    complement: "1:%d" % [2**32-1]
  }, keep: true

  data "range with *", {
    input:      "4294967000:*",
    elements:   [4_294_967_000..],
    entries:    [4_294_967_000..],
    ranges:     [4_294_967_000..],
    numbers:    RangeError,
    to_s:       "4294967000:*",
    normalize:  "4294967000:*",
    count:      2**32 - 4_294_967_000,
    complement: "1:4294966999",
  }, keep: true

  data "* sorts last", {
    input:      "5,*,7",
    elements:   [5, 7, :*],
    entries:    [5, :*, 7],
    ranges:     [5..5, 7..7, :*..],
    numbers:    RangeError,
    to_s:       "5,*,7",
    normalize:  "5,7,*",
    complement: "1:4,6,8:%d" % [2**32-1],
    count:      3,
  }, keep: true

  data "out of order", {
    input:      "46,7:6,15,3:1",
    elements:   [1..3, 6..7, 15, 46],
    entries:    [46, 6..7, 15, 1..3],
    ranges:     [1..3, 6..7, 15..15, 46..46],
    numbers:    [1, 2, 3, 6, 7, 15, 46],
    ordered:    [46, 6, 7, 15, 1, 2, 3],
    to_s:       "46,7:6,15,3:1",
    normalize:  "1:3,6:7,15,46",
    count:      7,
    complement: "4:5,8:14,16:45,47:*",
  }, keep: true

  data "adjacent", {
    input:      "1,2,3,5,7:9,10:11",
    elements:   [1..3, 5,    7..11],
    entries:    [1, 2, 3, 5, 7..9, 10..11],
    ranges:     [1..3, 5..5, 7..11],
    numbers:    [1, 2, 3, 5, 7, 8, 9, 10, 11],
    to_s:       "1,2,3,5,7:9,10:11",
    normalize:  "1:3,5,7:11",
    count:      9,
    complement: "4,6,12:*",
  }, keep: true

  data "overlapping", {
    input:      "1:5,3:7,10:9,10:11",
    elements:   [1..7, 9..11],
    entries:    [1..5, 3..7, 9..10, 10..11],
    ranges:     [1..7, 9..11],
    numbers:    [1, 2, 3, 4, 5, 6, 7,  9, 10, 11],
    ordered:    [1,2,3,4,5,  3,4,5,6,7,  9,10,  10,11],
    to_s:       "1:5,3:7,10:9,10:11",
    normalize:  "1:7,9:11",
    count:      10,
    count_dups:  4,
    complement: "8,12:*",
  }, keep: true

  data "contained", {
    input:      "1:5,3:4,9:11,10",
    elements:   [1..5, 9..11],
    entries:    [1..5, 3..4, 9..11, 10],
    ranges:     [1..5, 9..11],
    numbers:    [1, 2, 3, 4, 5, 9, 10, 11],
    ordered:    [1,2,3,4,5,  3,4,  9,10,11,  10],
    to_s:       "1:5,3:4,9:11,10",
    normalize:  "1:5,9:11",
    count:      8,
    count_dups: 3,
    complement: "6:8,12:*",
  }, keep: true

  data "multiple *", {
    input:      "2:*,3:*,*",
    elements:   [2..],
    entries:    [2.., 3.., :*],
    ranges:     [2..],
    numbers:    RangeError,
    to_s:       "2:*,3:*,*",
    normalize:  "2:*",
    count:      2**32 - 2,
    count_dups: 2**32 - 2,
    complement: "1",
  }, keep: true

  data "array", {
    input:      ["1:5,3:4", 9..11, "10", 99, :*],
    elements:   [1..5, 9..11, 99, :*],
    entries:    [1..5, 9..11, 99, :*],
    ranges:     [1..5, 9..11, 99..99, :*..],
    numbers:    RangeError,
    to_s:       "1:5,9:11,99,*",
    normalize:  "1:5,9:11,99,*",
    count:      10,
    complement: "6:8,12:98,100:#{2**32 - 1}",
  }, keep: true

  data "nested array", {
    input:      [["1:5", [3..4], [[[9..11, "10"], 99], :*]]],
    elements:   [1..5, 9..11, 99, :*],
    entries:    [1..5, 9..11, 99, :*],
    ranges:     [1..5, 9..11, 99..99, :*..],
    numbers:    RangeError,
    to_s:       "1:5,9:11,99,*",
    normalize:  "1:5,9:11,99,*",
    count:      10,
    complement: "6:8,12:98,100:#{2**32 - 1}",
  }, keep: true

  data "Set", {
    input:      Set[*(9..11), :*, 99, *(1..5)],
    elements:   [1..5, 9..11, 99, :*],
    entries:    [1..5, 9..11, 99, :*],
    ranges:     [1..5, 9..11, 99..99, :*..],
    numbers:    RangeError,
    to_s:       "1:5,9:11,99,*",
    normalize:  "1:5,9:11,99,*",
    count:      10,
    complement: "6:8,12:98,100:#{2**32 - 1}",
  }, keep: true

  data "empty", {
    input:      nil,
    elements:   [],
    entries:    [],
    ranges:     [],
    numbers:    [],
    to_s:       "",
    normalize:  nil,
    count:      0,
    complement: "1:*",
  }, keep: true

  test "#elements" do |data|
    assert_equal data[:elements], SequenceSet.new(data[:input]).elements
  end

  def assert_seqset_enum(expected, seqset, enum)
    array = []
    assert_equal seqset, seqset.send(enum) { array << _1 }
    assert_equal expected, array

    array = []
    assert_equal seqset, seqset.send(enum).each { array << _1 }
    assert_equal expected, array

    assert_equal expected, seqset.send(enum).to_a
  end

  test "#each_element" do |data|
    seqset   = SequenceSet.new(data[:input])
    expected = data[:elements]
    assert_seqset_enum expected, seqset, :each_element
  end

  test "#entries" do |data|
    assert_equal data[:entries], SequenceSet.new(data[:input]).entries
  end

  test "#each_entry" do |data|
    seqset   = SequenceSet.new(data[:input])
    expected = data[:entries]
    assert_seqset_enum expected, seqset, :each_entry
  end

  test "#each_range" do |data|
    seqset   = SequenceSet.new(data[:input])
    expected = data[:ranges]
    assert_seqset_enum expected, seqset, :each_range
  end

  test "#ranges" do |data|
    assert_equal data[:ranges], SequenceSet.new(data[:input]).ranges
  end

  test "#each_number" do |data|
    seqset   = SequenceSet.new(data[:input])
    expected = data[:numbers]
    if expected.is_a?(Class) && expected < Exception
      assert_raise expected do
        seqset.each_number do fail "shouldn't get here" end
      end
      enum = seqset.each_number
      assert_raise expected do enum.to_a end
      assert_raise expected do enum.each do fail "shouldn't get here" end end
    else
      assert_seqset_enum expected, seqset, :each_number
    end
  end

  test "#each_ordered_number" do |data|
    seqset   = SequenceSet.new(data[:input])
    expected = data[:ordered] || data[:numbers]
    if expected.is_a?(Class) && expected < Exception
      assert_raise expected do
        seqset.each_ordered_number do fail "shouldn't get here" end
      end
      enum = seqset.each_ordered_number
      assert_raise expected do enum.to_a end
      assert_raise expected do enum.each do fail "shouldn't get here" end end
    else
      assert_seqset_enum expected, seqset, :each_ordered_number
    end
  end

  test "#numbers" do |data|
    expected = data[:numbers]
    if expected.is_a?(Class) && expected < Exception
      assert_raise expected do SequenceSet.new(data[:input]).numbers end
    else
      assert_equal expected, SequenceSet.new(data[:input]).numbers
    end
  end

  test "#string" do |data|
    set = SequenceSet.new(data[:input])
    str = data[:to_s]
    str = nil if str.empty?
    assert_equal str, set.string
  end

  test "#deconstruct" do |data|
    set = SequenceSet.new(data[:input])
    str = data[:normalize]
    if str
      assert_equal [str], set.deconstruct
      set => SequenceSet[str]
    else
      assert_equal [], set.deconstruct
      set => SequenceSet[]
    end
  end

  test "#normalized_string" do |data|
    set = SequenceSet.new(data[:input])
    assert_equal data[:normalize], set.normalized_string
  end

  test "#normalize" do |data|
    set = SequenceSet.new(data[:input])
    assert_equal data[:normalize], set.normalize.string
    if data[:input]
    end
  end

  test "#normalize!" do |data|
    set = SequenceSet.new(data[:input])
    set.normalize!
    assert_equal data[:normalize], set.string
  end

  test "#to_s" do |data|
    assert_equal data[:to_s], SequenceSet.new(data[:input]).to_s
  end

  test "#count" do |data|
    assert_equal data[:count], SequenceSet.new(data[:input]).count
  end

  test "#count_with_duplicates" do |data|
    dups = data[:count_dups] || 0
    count = data[:count] + dups
    seqset = SequenceSet.new(data[:input])
    assert_equal count, seqset.count_with_duplicates
  end

  test "#count_duplicates" do |data|
    dups = data[:count_dups] || 0
    seqset = SequenceSet.new(data[:input])
    assert_equal dups, seqset.count_duplicates
  end

  test "#has_duplicates?" do |data|
    has_dups = !(data[:count_dups] || 0).zero?
    seqset = SequenceSet.new(data[:input])
    assert_equal has_dups, seqset.has_duplicates?
  end

  test "#valid_string" do |data|
    if (expected = data[:to_s]).empty?
      assert_raise DataFormatError do
        SequenceSet.new(data[:input]).valid_string
      end
    else
      assert_equal data[:to_s], SequenceSet.new(data[:input]).valid_string
    end
  end

  test "#~ and #complement" do |data|
    set = SequenceSet.new(data[:input])
    assert_equal(data[:complement], set.complement.to_s)
    assert_equal(data[:complement], (~set).to_s)
  end

  test "SequenceSet[input]" do |input|
    case (input = data[:input])
    when nil
      assert_raise DataFormatError do SequenceSet[input] end
    when String
      seqset = SequenceSet[input]
      assert_equal data[:input], seqset.to_s
      assert_equal data[:normalize], seqset.normalized_string
      assert seqset.frozen?
    else
      seqset = SequenceSet[input]
      assert_equal data[:normalize], seqset.to_s
      assert seqset.frozen?
    end
  end

  test "set == ~~set" do |data|
    set = SequenceSet.new(data[:input])
    assert_equal set, set.complement.complement
    assert_equal set, ~~set
  end

  test "set | ~set == full" do |data|
    set = SequenceSet.new(data[:input])
    assert_equal SequenceSet.new("1:*"), set + set.complement
  end

end
