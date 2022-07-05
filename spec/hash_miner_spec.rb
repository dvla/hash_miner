# frozen_string_literal: true

RSpec.describe HashMiner do
  before(:example) do
    @nasty_hash = { my: { super: { duper: { deeply: 'nested hash',
                                            is: [{ duper: 'gross', random: nil }, 'a', 1, nil] } },
                          hey: { duper: nil, blah: '', foo: [nil] },
                          deeply: [{ nested: 'hash' }] } }
  end

  it 'has a version number' do
    expect(HashMiner::VERSION).not_to be nil
  end

  context ' deep_contains?' do
    it 'returns true when key found' do
      expect(@nasty_hash.deep_contains?(key: :foo)).to be true
    end
    it 'returns false when key found' do
      expect(@nasty_hash.deep_contains?(key: [:foo])).to be false
      expect(@nasty_hash.deep_contains?(key: 'foo')).to be false
      expect(@nasty_hash.deep_contains?(key: nil)).to be false
    end

    it 'returns nil when not a Hash object' do
      expect(@nasty_hash.deep_contains?(key: nil, hash: [])).to be nil
      expect(@nasty_hash.deep_contains?(key: nil, hash: 'a')).to be nil
    end
  end

  context 'deep_count' do
    it 'returns the count when key found' do
      expect(@nasty_hash.deep_count(key: :foo)).to eq 1
      expect(@nasty_hash.deep_count(key: :duper)).to eq 3
    end

    it 'returns 0 when key found' do
      expect(@nasty_hash.deep_count(key: [:foo])).to eq 0
      expect(@nasty_hash.deep_count(key: 'foo')).to eq 0
      expect(@nasty_hash.deep_count(key: nil)).to eq 0
    end

    it 'returns 0 when not a Hash object' do
      expect(@nasty_hash.deep_count(key: nil, hash: [])).to eq 0
      expect(@nasty_hash.deep_count(key: nil, hash: 'a')).to eq 0
    end
  end

  context 'deep_find' do
    it 'returns Array with values for keys found' do
      expect(@nasty_hash.deep_find(key: :foo)).to eq([nil])
      expect(@nasty_hash.deep_find(key: :duper)).to eq([{ deeply: 'nested hash',
                                                          is: [{ duper: 'gross', random: nil }, 'a', 1, nil] }])
      expect(@nasty_hash.deep_find(key: :deeply)).to eq(['nested hash', { nested: 'hash' }])
    end

    it 'returns nil when key not found' do
      expect(@nasty_hash.deep_find(key: [:foo])).to be nil
      expect(@nasty_hash.deep_find(key: 'foo')).to be nil
      expect(@nasty_hash.deep_find(key: nil)).to be nil
    end

    it 'returns nil when not a Hash object' do
      expect(@nasty_hash.deep_find(key: nil, hash: [])).to be nil
      expect(@nasty_hash.deep_find(key: nil, hash: 'a')).to be nil
    end
  end

  context 'deep_compact' do
    it 'removes nil and empty values from Hash object' do
      expect(@nasty_hash.deep_compact).to eq({ my: { super: { duper: { deeply: 'nested hash',
                                                                       is: [{ duper: 'gross' }, 'a', 1,
                                                                            nil] } },
                                                     hey: { foo: [nil] },
                                                     deeply: [{ nested: 'hash' }] } })
    end
  end

  context 'deep_update_key' do
    it 'will error on uniqueness by default' do
      expect { @nasty_hash.deep_update(key: :duper, value: []) }.to raise_error KeyNotUniqueError
    end

    it 'will error on key missing by default' do
      expect { @nasty_hash.deep_update(key: :sup, value: []) }.to raise_error KeyNotFoundError
      expect { @nasty_hash.deep_update(key: [:duper], value: []) }.to raise_error KeyNotFoundError
      expect { @nasty_hash.deep_update(key: 'duper', value: []) }.to raise_error KeyNotFoundError
      expect { @nasty_hash.deep_update(key: nil, value: []) }.to raise_error KeyNotFoundError
    end

    it 'adds key and value to top level when key missing' do
      @nasty_hash = @nasty_hash.deep_update(key: :sup, value: [], error_on_missing: false)
      expect(@nasty_hash[:sup]).to eq([])
    end

    it 'will update all non-unique keys that match' do
      @nasty_hash = @nasty_hash.deep_update(key: :duper, value: :blah, error_on_uniqueness: false)

      @nasty_hash.deep_find(key: :duper).each do |value|
        expect(value).to eq(:blah)
      end
    end

    it 'will update unique keys that match' do
      @nasty_hash = @nasty_hash.deep_update(key: :super, value: :blah)

      values = @nasty_hash.deep_find(key: :super)
      expect(values.size).to eq(1)
      expect(values.first).to eq(:blah)
    end
  end

  context 'deep_remove' do
    it 'will error on uniqueness by default' do
      expect { @nasty_hash.deep_remove(key: :duper) }.to raise_error KeyNotUniqueError
    end

    it 'will remove all non-unique keys that match' do
      @nasty_hash = @nasty_hash.deep_remove(key: :duper, error_on_uniqueness: false)
      expect(@nasty_hash.deep_find(key: :duper)).to be nil
    end

    it 'will remove unique keys that match' do
      @nasty_hash = @nasty_hash.deep_remove(key: :super)
      expect(@nasty_hash.deep_find(key: :super)).to be nil
    end
  end
end
