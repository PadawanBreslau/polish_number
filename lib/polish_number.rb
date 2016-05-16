# encoding: utf-8

require "polish_number/version"

module PolishNumber
  HUNDREDS = ['', 'sto ', 'dwieście ', 'trzysta ', 'czterysta ', 'pięćset ', 'sześćset ',
    'siedemset ', 'osiemset ', 'dziewięćset ']

  TENS = ['', 'dziesięć ', 'dwadzieścia ', 'trzydzieści ', 'czterdzieści ', 'pięćdziesiąt ',
    'sześćdziesiąt ', 'siedemdziesiąt ', 'osiemdziesiąt ', 'dziewięćdziesiąt ']

  TEENS = ['', 'jedenaście ', 'dwanaście ', 'trzynaście ', 'czternaście ', 'piętnaście ',
    'szesnaście ', 'siedemnaście ', 'osiemnaście ', 'dziewiętnaście ']

  UNITIES = ['', 'jeden ', 'dwa ', 'trzy ', 'cztery ', 'pięć ', 'sześć ', 'siedem ', 'osiem ',
    'dziewięć ']

  ZERO = 'zero'

  THOUSANDS = {:one => 'tysiąc', :few => 'tysiące', :many => 'tysięcy'}

  def self.ending_helper(core)
    {:one => core, :few => core.dup << "y", :many => core.dup << "ów"}
  end

  MILLIONS = ending_helper("milion")
  BILLIONS = ending_helper("miliard")

  CURRENCIES = {
    :PLN => {:one => 'złoty', :few => 'złote', :many => 'złotych'},
    :EUR => {:one => 'euro', :few => 'euro', :many => 'euro'},
    :USD => {:one => 'dolar', :few => 'dolary', :many => 'dolarów'}
  }

  def self.translate(number, options={})
    handle_invalid_number(number)
    number = try_convert(number, options)

    unless (0..999999999999).include? number
      raise ArgumentError, 'number should be in 0..999999999999 range'
    end

    if number.zero?
      result = ZERO
    else
      digits = unpack_digits(number)
      digit_copy = digits.dup
      result = ''
      hundred_count = process_hundreds(digits.pop(3))
      thousend_count = process_greater(digits.pop(3), THOUSANDS)
      milion_count = process_greater(digits.pop(3), MILLIONS)
      billion_count = process_greater(digits.pop(3), BILLIONS)
      result << billion_count << milion_count << thousend_count << hundred_count
      result.strip!
    end

    if options[:currency]
      handle_improper_currency(options[:currency])
      currency = CURRENCIES[options[:currency]]
      result << ' '
      result << currency[classify_currency(number, digit_copy)]
    end

    result
  end

  private

  def self.handle_improper_currency(currency)
    if !CURRENCIES.has_key?(currency)
      raise ArgumentError, "unknown :currency option '#{currency.inspect}'. Choose one from: #{CURRENCIES.keys.inspect}"
    end
  end

  def self.handle_invalid_number(number)
    if !numeric?(number)
      raise ArgumentError, "Not a numeric value given: #{number}"
    end
  end

  def self.numeric?(number)
    !!Kernel.Float(number)
  rescue TypeError, ArgumentError
    false
  end

  def self.try_convert(number, options={})
    if number.kind_of? Fixnum
       number
    elsif number.kind_of? String
      number.to_i(options.fetch(:numeric_base){10})
    else
      number.to_i
    end
  end

  def self.unpack_digits(base)
    digits = []

    while base != 0 do
      base, last_digit = base.divmod(10)
      digits << last_digit
    end

    digits.reverse
  end

  def self.process_number(digit)
    UNITIES[digit.to_i]
  end

  def self.process_tens(digits)
    result = ''
    if digits[0] == 1 && digits[1] != 0
      result << TEENS[digits[1]]
    else
      result << TENS[digits[0]]
      result << UNITIES[digits[1]]
    end
    result
  end

  def self.process_hundreds(digits)
    if digits.size == 3
      HUNDREDS[digits.shift] + process_tens(digits)
    elsif digits.size == 2
      process_tens(digits)
    else
      process_number(digits.first)
    end
  end

  def self.process_greater(digits, level)
    number = process_hundreds(digits)
    if digits.nil? || digits.all?{|d| d.zero?}
      ' '
    else
      number + level[classify_ending(digits.last)] + ' '
    end
  end

  def self.classify_currency(number, digits)
    if number == 1
      :one
      # all numbers with 2, 3 or 4 at the end, but not teens
    elsif digits && (2..4).include?(digits[-1]) && digits[-2] != 1
      :few
    else
      :many
    end
  end

  def self.classify_ending(last_digit, semilast_digit = nil)
    case last_digit
    when 1 then :one
    when 2,3,4 then :few
    else :many
    end
  end

end
