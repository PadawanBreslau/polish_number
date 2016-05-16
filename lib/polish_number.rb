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

  MILLIONS = {:one => 'milion', :few => 'miliony', :many => 'milionów'}

  CURRENCIES = {
    :PLN => {:one => 'złoty', :few => 'złote', :many => 'złotych'},
    :EUR => {:one => 'euro', :few => 'euro', :many => 'euro'},
    :USD => {:one => 'dolar', :few => 'dolary', :many => 'dolarów'}
  }

  def self.handle_improper_currency(currency)
    if currency && !CURRENCIES.has_key?(currency)
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

  def self.try_convert(number)
    case number.class
    when Integer then number
    when String then number.to_i(options[:numeral_base] || 10)
    else number.to_i
    end
  end

  def self.translate(number, options={})
    handle_invalid_number(number)
    handle_improper_currency(options[:currency])
    number = try_convert(number)

    unless (0..999999999).include? number
      raise ArgumentError, 'number should be in 0..999999999 range'
    end

    if number == 0
      result = ZERO.dup
    else
      formatted_number = sprintf('%09.0f', number)
      digits = formatted_number.chars.map { |char| char.to_i }

      result = ''
      result << process_0_999(digits[0..2])
      result << millions(number/1000000, digits[0..2])
      result << ' '
      result << process_0_999(digits[3..5])
      result << thousands(number/1000, digits[3..5])
      result << ' '
      result << process_0_999(digits[6..9])
      result.strip!
    end

    if options[:currency]
      currency = CURRENCIES[options[:currency]]
      result << ' '
      result << currency[classify(number, digits)]
    end

    result
  end

  private

  def self.process_0_999(digits)
    result = ''
    result << HUNDREDS[digits[0]]

    if digits[1] == 1 && digits[2] != 0
      result << TEENS[digits[2]]
    else
      result << TENS[digits[1]]
      result << UNITIES[digits[2]]
    end

    result
  end

  def self.thousands(number, digits)
    if number == 0
      ''
    else
      THOUSANDS[classify(number, digits)]
    end
  end

  def self.millions(number, digits)
    if number == 0
      ''
    else
      MILLIONS[classify(number, digits)]
    end
  end

  def self.classify(number, digits)
    if number == 1
      :one
    # all numbers with 2, 3 or 4 at the end, but not teens
    elsif digits && (2..4).include?(digits[-1]) && digits[-2] != 1
      :few
    else
      :many
    end
  end
end
