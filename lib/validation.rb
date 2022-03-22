# frozen_string_literal: true

# module Validation
module Validation

  def card_blocked?
    if @current_account.card_blocked == 'true'

      puts 'Your card is Blocked, Please contact your branch'
      welcome_screen
    else
      false
    end
  end

  def valid_pin?
    3.times do |n|
      pin = Base64.strict_encode64(take_pin.to_s)
      return true if @current_account.pin == pin

      puts "Incorrect Pin\n\n"
      next unless n == 2

      @accounts_table = CSV.table('account.csv').each do |account|
        if account[:card_number] == @current_account.card_number
          account[:card_blocked] = 'true'
          break
        end
      end
      File.write('account.csv', @accounts_table)
      puts "You have entered wrong pin 3 times\nnow your card is blocked contact your bank for more details.."
      return false
    end
  end

  def amount_in_multiples_of_available_denominations?(amount)
    available_denominations = [100, 200, 500]
    if (amount % available_denominations[0]).zero? || (amount % available_denominations[1]).zero? || (amount % available_denominations[2]).zero?
      true
    else
      puts "The amount you entered is not multiple of available denominations\n\n"
      false
    end
  end

  def valid_pin_length?(pin)
    pin.to_s.length == 4
  end
end
