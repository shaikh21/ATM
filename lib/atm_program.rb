# frozen_string_literal: true
require 'base64'
require_relative 'atm'
require 'highline/import'
require 'colorize'

module ATM
  def self.start
    Atm.new
  end
end
