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
  # @param parent [String, Symbol, Array]
  #
  # @return [Array] with all values that match the key
  def deep_find(key:, hash: self, parent: nil)
    return nil unless hash.is_a? Hash
    return nil unless hash.deep_contains?(key: key)

    parent ? deep_find_parent_logic(hash: self, key: key, parent: parent) : deep_find_logic(hash: self, key: key)
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
  # @param parent [String, Symbol, Array] the parent key for the key you want to update
  #
  # @return [Hash] the object with specified key updated.
  def deep_update(key:, value:, error_on_missing: true, error_on_uniqueness: true, parent: nil)
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

    if parent
      deep_update_parent_flow(hash: self, key: key, value: value, parent: parent)
    else
      deep_update_logic(hash: self, key: key, value: value)
    end
  end

  # Removes specified key from nested hash.
  #
  # @param key [String] the key to remove.
  # @param error_on_uniqueness [Boolean] error if key not unique
  # @param parent [String, Symbol, Array] the parent key for the key you want to update
  #
  # @return [Hash] the object with specified key removed.
  def deep_remove(key:, error_on_uniqueness: true, parent: nil)
    return self unless is_a? Hash

    if error_on_uniqueness && (deep_count(key: key) > 1)
      raise KeyNotUniqueError, "Key: '#{key}' not unique | Pass 'error_on_uniqueness: false' if you do not care"
    end

    parent ? deep_remove_logic_parent(hash: self, key: key, parent: parent) : deep_remove_logic(hash: self, key: key)
  end

  private

  def deep_update_logic(hash:, key:, value:)
    hash.to_h do |k, v|
      if k.eql?(key)
        [k, value]
      elsif v.is_a?(Hash) && v.deep_contains?(key: key)
        [k, deep_update_logic(key: key, value: value, hash: v)]
      elsif v.is_a?(Array)
        [k, v.map do |item|
          if item.is_a?(Hash) && item.deep_contains?(key: key)
            deep_update_logic(key: key, value: value, hash: item)
          else
            item
          end
        end]
      else
        [k, v]
      end
    end
  end

  def deep_update_parent_flow(hash:, key:, value:, parent:)
    hash.to_h do |k, v|
      if (parent.is_a?(Array) && parent.include?(k)) || parent.eql?(k)
        case v
        when Hash
          [k, deep_update_logic(hash: v, key: key, value: value)]
        when Array
          [k, v.map do |item|
            if item.is_a?(Hash) && item.deep_contains?(key: key)
              deep_update_logic(key: key, value: value, hash: item)
            else
              item
            end
          end]
        else
          [k, v]
        end
      elsif v.is_a?(Hash) && v.deep_contains?(key: key)
        [k, deep_update_parent_flow(hash: v, key: key, value: value, parent: parent)]
      elsif v.is_a?(Array)
        [k, v.map do |item|
          if item.is_a?(Hash) && item.deep_contains?(key: key)
            deep_update_parent_flow(hash: item, key: key, value: value, parent: parent)
          else
            item
          end
        end]
      else
        [k, v]
      end
    end
  end

  def deep_remove_logic(hash:, key:)
    # filter_map removes nil from Array
    hash.filter_map do |k, v|
      if k.eql? key
        nil
      elsif v.is_a?(Hash) && v.deep_contains?(key: key)
        [k, deep_remove_logic(key: key, hash: v)]
      elsif v.is_a?(Array)
        [k, v.map do |item|
          if item.is_a?(Hash) && item.deep_contains?(key: key)
            deep_remove_logic(key: key, hash: item)
          else
            item
          end
        end]
      else
        [k, v]
      end
    end.to_h
  end

  def deep_remove_logic_parent(hash:, key:, parent:)
    hash.filter_map do |k, v|
      if (parent.is_a?(Array) && parent.include?(k)) || parent.eql?(k)
        case v
        when Hash
          [k, deep_remove_logic(key: key, hash: v)]
        when Array
          [k, v.map do |item|
            if item.is_a?(Hash) && item.deep_contains?(key: key)
              deep_remove_logic(key: key, hash: item)
            else
              item
            end
          end]
        else
          [k, v]
        end
      elsif v.is_a?(Hash) && v.deep_contains?(key: key)
        [k, deep_remove_logic_parent(hash: v, key: key, parent: parent)]
      elsif v.is_a?(Array)
        [k, v.map do |item|
          if item.is_a?(Hash) && item.deep_contains?(key: key)
            deep_remove_logic_parent(hash: item, key: key, parent: parent)
          else
            item
          end
        end]
      else
        [k, v]
      end
    end.to_h
  end

  def deep_find_logic(hash:, key:)
    hash.filter_map do |k, v|
      if k.eql? key
        v
      elsif v.is_a?(Hash)
        deep_find_logic(hash: v, key: key)
      elsif v.is_a?(Array)
        [v.filter_map do |item|
          deep_find_logic(hash: i, key: key) if item.is_a?(Hash) && item.deep_contains?(key: key)
        end]
      end
    end.flatten
  end

  def deep_find_parent_logic(hash:, key:, parent:)
    hash.filter_map do |k, v|
      if (parent.is_a?(Array) && parent.include?(k)) || parent.eql?(k)
        case v
        when Hash
          deep_find_logic(key: key, hash: v)
        when Array
          [v.filter_map do |item|
            deep_find_logic(key: key, hash: item) if item.is_a?(Hash) && item.deep_contains?(key: key)
          end]
        end
      elsif v.is_a?(Hash) && v.deep_contains?(key: key)
        deep_find_parent_logic(hash: v, key: key, parent: parent)
      elsif v.is_a?(Array)
        [v.filter_map do |item|
          deep_find_parent_logic(hash: item, key: key, parent: parent) if item.is_a?(Hash) && item.deep_contains?(key: key)
        end]
      end
    end.flatten
  end
end
