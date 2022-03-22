# frozen_string_literal: true

require 'byebug'
require_relative 'validation'
# class Transaction
class Transaction
  include Validation

  private

  def initialize(current_account, type, amount = nil)
    @current_account = current_account
    @type = type
    @amount = amount
    @transaction_number = File.readlines('transaction.csv').length
    @row = "#{@transaction_number},#{@current_account.card_number},#{@type},#{Time.now.strftime('%d/%m/%Y %I:%M:%S:%P')},#{@amount},"
    validate_type if valid_pin?
  end

  def validate_type
    case @type
    when :Withdrawl then withdrawl
    when :Deposit then deposit
    when :'Change Pin' then change_pin
    when :'Request Chequebook' then request_chequebook
    end
  end

  def sufficient_balance?
    return true if @current_account.balance >= @amount

    puts 'Insufficient balance'
    @status = 'Fail'
    update_transaction_file(@row << @status << "\n")
    false
  end

  def withdrawl
    return unless sufficient_balance?

    if amount_in_multiples_of_available_denominations?(@amount)
      @status = 'Success'
      puts "Successfully withdrawl of Rs #{@amount}"
      update_transaction_file(@row << @status << "\n")
      update_account_file(:Withdrawl, amount: @amount)
    else
      @status = 'Fail'
      update_transaction_file(@row << @status << "\n")
    end
  rescue Interrupt
    rescue_interrupt
  end

  def deposit
    @status = 'Success'
    update_account_file(:Deposit, amount: @amount)
    puts "Successfully deposit of Rs #{@amount}"
    update_transaction_file(@row << @status << "\n")
  rescue Interrupt
    rescue_interrupt
  end

  def change_pin
    pins = take_change_pins
    if pins.first == pins.last
      update_account_file(@type, pin: Base64.strict_encode64(pins.first.to_s))
      @status = 'Success'
      puts 'Successfully pin changed. '
    else
      puts 'New pin and confirm pin did not matched'
      @status = 'Fail'
    end
    update_transaction_file(@row << @status << "\n")
  rescue Interrupt
    rescue_interrupt
  end

  def take_pin
    Integer(ask('Enter your Pin:') { |q| q.echo = '*' })
  rescue ArgumentError
    puts 'Please enter pin in numbers'
    take_pin
  end

  def take_change_pins
    new_pin = Integer(ask('Enter new pin:') { |q| q.echo = '*' })
    if valid_pin_length?(new_pin)
      confirm_pin = Integer(ask('Enter confirm pin:') { |q| q.echo = '*' })
      [new_pin, confirm_pin]
    else
      puts 'pin must be 4 digits.'
      take_change_pins
    end
  rescue ArgumentError
    puts 'Please enter pin in numbers'
    take_change_pins
  end

  def request_chequebook
    @status = 'Success'
    puts "Hey #{@current_account.name.capitalize}, Your request for chequebook is accepted"
    update_transaction_file(@row << @status << "\n")
  rescue Interrupt
    rescue_interrupt
  end

  def update_account_file(transaction_type, amount: nil, pin: nil)
    data = CSV.table('account.csv')
    data.each do |entry|
      next unless entry[:card_number] == @current_account.card_number

      case transaction_type
      when :Withdrawl then entry[:balance] -= amount
      when :Deposit then entry[:balance] += amount
      when :'Change Pin' then entry[:pin] = pin
      end
      File.write('account.csv', data)
      break
    end
  end

  def update_transaction_file(data)
    File.open('transaction.csv', 'a') do |row|
      row << data
    end
  end

  def rescue_interrupt
    thank_you
    @status = 'Fail'
    update_transaction_file(@row << @status << "\n")
  end

  def thank_you
    puts "\nThank You for using the ATM"
    sleep(2)
  end
end
