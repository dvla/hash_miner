# frozen_string_literal: true

require_relative 'hash_miner/version'
require_relative 'hash_miner/hash'
require_relative 'hash_miner/errors'

require 'logger'

# HashMiner gem
module HashMiner
  class Error < StandardError; end

  LOG = Logger.new($stdout)
  LOG.formatter = proc { |severity, datetime, _progname, msg| "[#{datetime}  #{severity}  HashMiner] -- #{msg}\n" }
end
