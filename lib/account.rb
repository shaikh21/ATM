# frozen_string_literal: true

require 'csv'
# class Account
class Account
  attr_accessor :name, :card_number, :pin, :balance, :transactions, :card_blocked

  def initialize(name, card_number, pin, balance, card_blocked)
    @name = name
    @card_number = card_number
    @pin = pin
    @balance = balance
    @card_blocked = card_blocked
  end

  def self.find_by_card_number(card_number)
    CSV.table('/account.csv').each do |entry|
      if entry[:card_number] == card_number
        return new(entry[:name], entry[:card_number], entry[:pin], entry[:balance], entry[:card_blocked])
      end
    end
    nil
  end
end
