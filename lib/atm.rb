# frozen_string_literal: true

require_relative 'account'
require_relative 'validation'
require_relative 'transaction'
require 'csv'
require 'base64'

# class ATM
class Atm
  include Validation
  def initialize
    welcome_screen
  end

  private

  def thank_you
    puts "\nThank You for using the ATM"
    sleep(2)
    welcome_screen
  end

  def clear
    sleep(4)
    puts `clear`
  end

  def welcome_screen(str = nil)
    thank_you if str == :exit
    loop do
      clear
      print "---------------------------- Welcome to the ATM ----------------------------\n\n".colorize(:light_green), 'Enter card number => '
      @card_number = gets.chomp.to_i
      get_current_account(@card_number)
      puts "Hello, #{@current_account.name.capitalize}\n\n"
      display_options(:initial_options) unless card_blocked?
      thank_you
    end
  rescue Interrupt
    abort("\nThank You for using the ATM")
  end

  def get_current_account(card_number)
    return if @current_account = Account.find_by_card_number(card_number)

    puts 'Card not valid'
    thank_you
    welcome_screen
  end

  def display_options(option_type)
    case option_type
    when :initial_options
      puts "\n1. Banking", '2. Mini Statement', '3. Change Pin', '4. Request Chequebook', '5. Exit', "\nSelect option :"
      user_choice = Integer(gets.chomp)
      execute_initial_option(user_choice)
    when :banking_options
      puts "\n1. Withdrawl", '2. Balance', '3. Deposit', '4. Fast Cash', '5. Back', '6. Exit', "\nSelect option :"
      user_choice = Integer(gets.chomp)
      execute_banking_option(user_choice)
    end
  rescue ArgumentError
    puts 'Please enter your option in number.'
    display_options(option_type)
  end

  def execute_initial_option(option)
    case option
    when 1 then display_options(:banking_options)
    when 2 then mini_statement
    when 3 then Transaction.new(@current_account, :'Change Pin')
    when 4 then Transaction.new(@current_account, :'Request Chequebook')
    when 5 then welcome_screen(:exit)
    else
      puts "#{option} is not a right option", 'Please select the righ option.'
      display_options(:initial_options)
    end
  end

  def execute_banking_option(option)
    case option
    when 1 then Transaction.new(@current_account, :Withdrawl, take_amount(:Withdrawl))
    when 2 then display_balance
    when 3 then Transaction.new(@current_account, :Deposit, take_amount(:Deposit))
    when 4 then display_fast_cash_options
    when 5 then display_options(:initial_options)
    when 6 then welcome_screen(:exit)
    else
      puts "#{option} is not a right option", "Please select the righ option.\n"
      display_options(:banking_options)
    end
  end

  def take_amount(transaction_type)
    case transaction_type
    when :Withdrawl
      available_denominations = [100, 200, 500]
      puts "\nAvailable denominations are =>\t#{available_denominations[0]}\t#{available_denominations[1]}\t#{available_denominations[2]}\n\n"
      puts "\nPlease enter amount in multiples of available denominations:"
      Integer(gets.chomp)
    when :Deposit
      puts 'Enter amount:'
      Integer(gets.chomp)
    end
  rescue ArgumentError
    puts 'Please enter amount in numbers.'
    take_amount(transaction_type)
  end

  def display_balance
    puts "\nBalance => #{@current_account.balance}\n\n" if valid_pin?
  end

  def mini_statement
    return unless valid_pin?

    transactions = []
    CSV.table('/transaction.csv').each do |row|
      next unless row[:card_number] == @current_account.card_number && row[:status] == 'Success'

      transaction_number = row[:transaction_number].to_s.rjust(4, '0')
      transactions.append(row[:amount].nil? ? "#{transaction_number} #{row[:time]} #{row[:type]}" : "#{transaction_number} #{row[:time]} #{row[:type]} of Rs =>#{row[:amount]}")
      next
    end
    puts transactions.empty? ? "You don't have any Transactions" : transactions.last(5)
    sleep(3)
  end

  def display_fast_cash_options
    puts '1. 1000', '2. 2000', '3. 5000', '4. 10000', '5. Back', '6. Exit', "\nselect option => "
    execute_fast_cash(Integer(gets.chomp))
  rescue ArgumentError
    puts 'Please enter your option in number:'
    display_fast_cash_options
  end

  def execute_fast_cash(option)
    case option
    when 1 then Transaction.new(@current_account, :Withdrawl, 1_000)
    when 2 then Transaction.new(@current_account, :Withdrawl, 2_000)
    when 3 then Transaction.new(@current_account, :Withdrawl, 5_000)
    when 4 then Transaction.new(@current_account, :Withdrawl, 10_000)
    when 5 then display_options(:banking_options)
    when 6 then welcome_screen
    else
      puts "#{option} is not a right option", 'Please select the righ option.'
      display_fast_cash_options
    end
  end

  def take_pin
    Integer(ask('Enter your Pin:') { |q| q.echo = '*' })
  rescue ArgumentError
    puts 'Please enter pin in numbers'
    take_pin
  end
end
