# The aim of this class is to take a number of ordered enumerators and then
# create an Enumerator that emits their values in ascending order.
#
# Some assumptions:
#   * The enumerators passed in emit their values in ascending order.
#   * The enumerators emit values which are Comparable[1] with each other.
#   * The enumerators can be finite *or* infinite.
#
# Please note: Your code must not only pass the tests, but also be a well
# behaved Enumerator.
#
# The Enumerator[2] documentation might be useful.
#
# [1] http://www.ruby-doc.org/core-1.9.3/Comparable.html
# [2] http://www.ruby-doc.org/core-1.9.3/Enumerator.html
#
# This is a stub implementation that causes failures in in the test suite, but
# no errors.
#
# You can run the test suite with: `ruby combined_ordered_enumerator.rb`.
class CombinedOrderedEnumerator < Enumerator
  class UnorderedEnumerator < RuntimeError
    attr :enumerator

    def initialize(enumerator, new_variable)
      @enumerator = enumerator
      @new_variable = new_variable
    end

  end

  class IncomparableEnumerators < StandardError
    attr :first_enumerator , :second_enumerator

    def initialize(first_enumerator,second_enumerator)
      @first_enumerator = first_enumerator
      @second_enumerator = second_enumerator
    end

  end

  def initialize(*enumerators)
    @enumerators = enumerators


    super() do |yielder|
      unless self.all_enumerators_are_empty
        @last_numbers = Hash[@enumerators.collect { |v| [v, v.peek] }]

        loop do
          enumerator = self.select_enumerator_for_next_value
          unless enumerator.nil?
            yielder.yield enumerator.next
          else
            break
          end
        end

      else
        yielder
      end

    end
  end


  def select_enumerator_for_next_value
    lower_value = nil
    num_lower_value = nil
    empty_enumerators = []

    #The numerator is nil when there is not a next value and it necessary end the sequence. For example when you have only finite sequences
    @enumerators.each_with_index do |enumerator, index|
      unless self.enumerator_reach_last_element(enumerator)
        #check if the select numerator has asceding orderer
        self.check_ascending_order_infinite_sequences(enumerator)

        if lower_value.nil?
          lower_value = enumerator.peek
          num_lower_value = enumerator
        elsif not self.comparable_elements(num_lower_value,enumerator)
          raise IncomparableEnumerators.new(num_lower_value,enumerator), "The enumerators have to be elements comparables between them. The incomparables elements are : #{num_lower_value.peek}, #{enumerator.peek}"
        elsif enumerator.peek < lower_value
          lower_value = enumerator.peek
          num_lower_value = enumerator
        end
      else
        empty_enumerators << enumerator
      end
    end

    #We delete the enumerators that reach the last element
    if empty_enumerators.size > 0
      empty_enumerators.each do |enumerator|
        @enumerators.delete(enumerator)
      end
    end

    num_lower_value
  end



  #Make sure the call the method when there is a peek value and the enumerator not reach the last value
  def check_ascending_order_infinite_sequences(enumerator)
    last_number = @last_numbers[enumerator]

    if enumerator.peek < last_number
      raise UnorderedEnumerator.new(enumerator), "The enumerator #{enumerator.to_s} must be ordered in ascending order"
    else
      @last_numbers[enumerator] = enumerator.peek
    end
  end

  def all_enumerators_are_empty
    empty_enumerators = []
    @enumerators.each do |enumerator|
      if self.enumerator_reach_last_element(enumerator)
        empty_enumerators << enumerator
      end
    end

    empty_enumerators_result = empty_enumerators.size == @enumerators.size

    #We delete the empty enumerators
    unless empty_enumerators_result
      empty_enumerators.each do |empty_enumerator|
        @enumerators.delete(empty_enumerator)
      end
    end

    empty_enumerators_result
  end

  #Indicate if a enumerator reach the last element.
  def enumerator_reach_last_element(enumerator)
    finished = false
    begin
      enumerator.peek
    rescue StopIteration => e
      finished = true
    end

    finished
  end

  def comparable_elements(first_enumerator,second_enumerator)

    first_element = first_enumerator.peek
    second_element = second_enumerator.peek

    first_element <=> second_element
  end

end

if $0 == __FILE__
  require 'minitest/autorun'
  require 'minitest/pride'

  class CombinedOrderedEnumeratorTest < Minitest::Test
    def test_enumerating_nothing
      enumerator = CombinedOrderedEnumerator.new()
      assert_equal [], enumerator.first(10)
    end

    def test_enumerating_with_two_empty_arrays
      enumerator = CombinedOrderedEnumerator.new([].to_enum, [].to_enum)
      assert_equal [], enumerator.to_a
    end

    def test_enumerating_with_a_single_enumerator
      enumerator = CombinedOrderedEnumerator.new((1..5).to_enum)
      assert_equal [1, 2, 3, 4, 5], enumerator.take(10)
    end

    def test_enumerating_with_one_empty_array_and_finite_sequence
      enumerator = CombinedOrderedEnumerator.new([].to_enum, (1..10).to_enum)
      assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], enumerator.map { |x| x }
    end

    def test_enumerating_with_one_empty_array_and_finite_sequence_with_switched_args
      enumerator = CombinedOrderedEnumerator.new((1..10).to_enum, [].to_enum)
      assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], enumerator.first(20)
    end

    def test_enumerating_an_infinite_sequence_and_finite_one
      enumerator = CombinedOrderedEnumerator.new(fibonacci, (1..10).to_enum)
      assert_equal [0, 1, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 8, 8, 9, 10, 13, 21, 34], enumerator.take(20)
    end

    def test_enumerating_two_infinite_sequences
      enumerator = CombinedOrderedEnumerator.new(fibonacci, sum_of_natural_numbers)
      assert_equal [0, 1, 1, 1, 2, 3, 3, 5, 6, 8, 10, 13, 15, 21, 21, 28, 34, 36, 45, 55], enumerator.first(20)
    end

    def test_enumerating_three_finite_sequences
      enumerator = CombinedOrderedEnumerator.new((1..5).to_enum, (1..3).to_enum, (4..10).to_enum)
      assert_equal [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9, 10], enumerator.take(20)
    end

    def test_enumerating_three_infinite_sequences
      enumerator = CombinedOrderedEnumerator.new(fibonacci, fibonacci, fibonacci)
      assert_equal [0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2], enumerator.first(12)
    end

    def test_raises_unordered_enumerator_exception_if_enumerator_isnt_in_ascending_order
      enumerator = CombinedOrderedEnumerator.new(10.downto(1))

      assert_raises(CombinedOrderedEnumerator::UnorderedEnumerator) do
        enumerator.take(20)
      end
    end

    def test_raising_unordered_enumerator_should_reference_enumerator
      decending_enumerator = 10.downto(1)
      enumerator = CombinedOrderedEnumerator.new(decending_enumerator)

      begin
        enumerator.take(2)
        assert false
      rescue CombinedOrderedEnumerator::UnorderedEnumerator => exception
        assert_equal decending_enumerator, exception.enumerator
      end
    end

    def test_raising_tricky_natural_sum
      tricky = tricky_sum_of_natural_numbers
      enumerator = CombinedOrderedEnumerator.new(tricky)

      assert_raises(CombinedOrderedEnumerator::UnorderedEnumerator) do
        enumerator.take(20)
      end
    end

    def test_raising_uncomparable_elements
      enumerator = CombinedOrderedEnumerator.new(fibonacci,('a'..'z').to_enum)

      assert_raises(CombinedOrderedEnumerator::IncomparableEnumerators) do
        enumerator.take(20)
      end
    end

    def test_ascending_order_two_infite_sequences
      enumerator = CombinedOrderedEnumerator.new(pair_numbers,odd_numbers)
      assert_equal [0,1,2,3,4,5,6,7,8,9,10,11], enumerator.first(12)
    end

    private

    class FibonacciEnumerator < Enumerator
      def initialize
        super() do |yielder|
          a, b = 0, 1

          loop do
            yielder.yield a
            a, b = b, (a + b)
          end
        end
      end
    end

    def fibonacci
      FibonacciEnumerator.new
    end

    class SumOfNaturalNumbersEnumerator < Enumerator
      def initialize
        super() do |yielder|
          n = 1

          loop do
            yielder.yield((n * (n + 1)) / 2)
            n += 1
          end
        end
      end
    end

    class PairNumbers < Enumerator
      def initialize
        super() do |yielder|
          n = 0

          loop do
            if n%2 == 0
              yielder.yield n
            end
            n += 1
          end
        end
      end
    end

    class OddNumbers < Enumerator
      def initialize
        super() do |yielder|
          n = 0

          loop do
            if n%2 == 1
              yielder.yield n
            end
            n += 1
          end
        end
      end
    end

    class TrickySumOfNaturalNumbersEnumerator < Enumerator
      def initialize
        super() do |yielder|
          n = 1

          loop do
            if n < 4
              yielder.yield((n * (n + 1)) / 2)
            else
              previous_number = ((n-1)*(n-2))/2 - 1
              yielder.yield(previous_number)
            end
            n += 1
          end
        end
      end
    end

    def sum_of_natural_numbers
      SumOfNaturalNumbersEnumerator.new
    end

    def tricky_sum_of_natural_numbers
      TrickySumOfNaturalNumbersEnumerator.new
    end

    def pair_numbers
      PairNumbers.new
    end

    def odd_numbers
      OddNumbers.new
    end
  end

end
