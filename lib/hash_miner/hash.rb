# frozen_string_literal: true

# Adds additional methods to the Hash class
class Hash
  include HashMiner

  # Checks if the key exists within a Hash
  #
  # @param key [String, Symbol] the key you want to check
  # @param hash [Hash] the hash obj - used for recursive calling
  #
  # @return [Boolean] whether the key was found
  def deep_contains?(key:, hash: self)
    return nil unless hash.is_a? Hash
    return true if hash.include? key

    hash.filter_map do |_k, v|
      case v
      when Hash
        [v.deep_contains?(key: key)]
      when Array
        [v.map { |i| deep_contains?(key: key, hash: i) }]
      else
        false
      end
    end.flatten.include? true
  end

  # Count the number of occurrences a key has in a Hash
  #
  # @param key [String, Symbol]
  # @param hash [Hash]
  #
  # @return [Integer] the number of occurrences for a given key
  def deep_count(key:, hash: self)
    found = 0
    return found unless hash.is_a? Hash
    return found unless hash.deep_contains?(key: key)

    hash.each do |k, v|
      found += 1 if k.eql? key
      found += deep_count(hash: v, key: key) if v.is_a?(Hash)
      v.each { |i| found += deep_count(hash: i, key: key) } if v.is_a?(Array)
    end

    found
  end

  # Finds the value for a given key
  #
  # @param key [String, Symbol]
  # @param hash [Hash]
  #
  # @return [Array] with all values that match the key
  def deep_find(key:, hash: self)
    return nil unless hash.is_a? Hash
    return nil unless hash.deep_contains?(key: key)

    hash.filter_map do |k, v|
      if k.eql? key
        v
      elsif v.is_a?(Hash)
        deep_find(hash: v, key: key)
      elsif v.is_a?(Array)
        [v.filter_map { |i| deep_find(hash: i, key: key) }]
      end
    end.flatten
  end

  # Removed nil/empty from Hash
  #
  # @return [Hash] with no nil/empty values
  def deep_compact
    if is_a?(Hash)
      to_h do |k, v|
        case v
        when Hash
          [k, v.deep_compact]
        when Array
          [k, v.map do |i|
            i.is_a?(Hash) ? i.deep_compact : i
          end]
        else
          [k, v]
        end
      end.delete_if { |_, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
    else
      self
    end
  end

  # Updates specified key in nested hash.
  #
  # @param key [String, Symbol] the key to update
  # @param value [String] the value to be set
  # @param error_on_missing [Boolean] error if key missing
  # @param error_on_uniqueness [Boolean] error if key not unique
  #
  # @return [Hash] the object with specified key updated.
  def deep_update(key:, value:, error_on_missing: true, error_on_uniqueness: true)
    return self unless is_a? Hash

    if error_on_uniqueness && (deep_count(key: key) > 1)
      raise KeyNotUniqueError, "Key: '#{key}' not unique | Pass 'error_on_uniqueness: false' if you do not care"
    end

    unless deep_contains?(key: key)
      if error_on_missing
        raise KeyNotFoundError,
              "Key: '#{key}' not found in hash | Pass 'error_on_missing: false' if you do not care"
      end

      LOG.warn('Key not found in hash, adding to the top level')

      hash = dup
      hash[key] = value
      return hash
    end

    to_h do |k, v|
      if k.eql?(key)
        [k, value]
      elsif v.is_a?(Hash) && v.deep_contains?(key: key)
        [k, v.deep_update(key: key, value: value, error_on_missing: error_on_missing, error_on_uniqueness: error_on_uniqueness)]
      elsif v.is_a?(Array)
        [k, v.map do |item|
          if item.is_a?(Hash) && item.deep_contains?(key: key)
            item.deep_update(key: key, value: value, error_on_missing: error_on_missing, error_on_uniqueness: error_on_uniqueness)
          else
            item
          end
        end]
      else
        [k, v]
      end
    end
  end

  # Removes specified key from nested hash.
  #
  # @param key [String] the key to remove.
  #
  # @return [Hash] the object with specified key removed.
  def deep_remove(key:, error_on_uniqueness: true)
    return self unless is_a? Hash

    if error_on_uniqueness && (deep_count(key: key) > 1)
      raise KeyNotUniqueError, "Key: '#{key}' not unique | Pass 'error_on_uniqueness: false' if you do not care"
    end

    # filter_map removes nil from Array
    filter_map do |k, v|
      if k.eql? key
        nil
      elsif v.is_a?(Hash)
        [k, v.deep_remove(key: key, error_on_uniqueness: error_on_uniqueness)]
      elsif v.is_a?(Array)
        [k, v.map do |item|
          if item.is_a?(Hash) && item.deep_contains?(key: key)
            item.deep_remove(key: key, error_on_uniqueness: error_on_uniqueness)
          else
            item
          end
        end]
      else
        [k, v]
      end
    end.to_h
  end
end
