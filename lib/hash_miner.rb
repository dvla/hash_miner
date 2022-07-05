# frozen_string_literal: true

require_relative 'hash_miner/version'
require_relative 'hash_miner/hash'
require_relative 'hash_miner/errors'

require 'pry'
require 'logger'

module HashMiner
  class Error < StandardError; end

  LOG = Logger.new($stdout)
end
