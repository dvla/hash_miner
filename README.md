# HashMiner

Ever experienced the pain of working with deeply nested hashes in Ruby? 

HashMiner expands the base Hash class in Ruby to provide helpful methods to traverse and manipulate your Hash Object regardless of complexity.

The following gives a flavour of how HashMiner can help solve headaches when working with complex hashes:

```ruby
require 'hash_miner'

hash = { my: { super: { duper: { deeply: 'nested hash' } } } }

# Deleting a key #
# Without HashMiner
hash[:my][:super].delete(:duper) # => {:deeply=>"nested hash"}
# With HashMiner
hash.deep_remove(key: :duper) # => {:my=>{:super=>{}}}

# Updating a key #
# Without HashMiner
hash[:my][:super][:duper][:deeply] = 'modified nested hash' # => "modified nested hash"
# With HashMiner
hash.deep_update(key: :deeply, value: 'modified nested hash') # => {:my=>{:super=>{:duper=>{:deeply=>"modified nested hash"}}}}

# Checking a key exists #
# Without HashMiner
hash[:my][:super][:duper][:deeply] # => "nested hash"
# With HashMiner
hash.deep_find(key: :deeply) # => ["nested hash"]
```

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add hash_miner

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install hash_miner

## Usage

- HashMiner methods have no side-effects

### Methods available
#### deep_update

- Updates all values that match the given key

```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: :nasty } } }

nasty_hash.deep_update(key: :nasty, value: :complicated_hash) # => {:my=>{:pretty=>[{:nasty=>:complicated_hash}, nil], :is=>{:pretty=>:nasty}}}

# Errors on uniqueness
nasty_hash.deep_update(key: :pretty, value: :super_duper) # => throws KeyNotUniqueError
nasty_hash.deep_update(key: :pretty, value: :super_duper, error_on_uniqueness: false) # => {:my=>{:pretty=>:super_duper, :is=>{:pretty=>:super_duper}}}

# Errors on missing
nasty_hash.deep_update(key: :huh, value: :where_am_i) # => throws KeyNotFoundError
nasty_hash.deep_update(key: :pretty, value: :super_duper, error_on_missing: false) # => {:my=>{:pretty=>[{:nasty=>:hash}, nil], :is=>{:pretty=>:nasty}}, :huh=>:where_am_i}

# Pass through parent flag for scoping
nasty_hash.deep_update(key: :pretty, value: :super_duper, error_on_uniqueness: false, parent: :is) # => {:my=>{:pretty=>[{:nasty=>:hash}, nil], :is=>{:pretty=>:super_duper}}}

```
---
#### deep_remove

- Removes all values that match the given key

```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: :nasty } } }

nasty_hash.deep_remove(key: :nasty) # => {:my=>{:pretty=>[{}, nil], :is=>{:pretty=>:nasty}}}

# Errors on uniqueness
nasty_hash.deep_remove(key: :pretty) # => throws KeyNotUniqueError
nasty_hash.deep_remove(key: :pretty, error_on_uniqueness: false) # => {:my=>{:is=>{}}}

# Pass through parent flag for scoping
nasty_hash.deep_remove(key: :pretty, error_on_uniqueness: false, parent: :is) # => { my: { pretty: [{ nasty: :hash }, nil], is: { } } }
```
---
#### deep_find

- Returns all values that match the given key

```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: :nasty } } }

nasty_hash.deep_find(key: :nasty) # => [:hash]
nasty_hash.deep_find(key: :pretty) # => [{:nasty=>:hash}, nil, :nasty]

# Pass through parent flag for scoping
nasty_hash.deep_find(key: :pretty, parent: :is) # => [:nasty]
```
---
#### deep_compact

- Removes nil and empty values from Hash
- Will not remove values within an Array i.e `[nil, {}]` will remain
```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: {}, nasty: nil } } }

nasty_hash.deep_compact # => {:my=>{:pretty=>[{:nasty=>:hash}, nil]}}
```
---
#### deep_count

- Returns a count for the given key
```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: :nasty } } }

nasty_hash.deep_count(key: :pretty) # => 2 
nasty_hash.deep_count(key: :nasty) # => 1 
```
---
#### deep_contains?

- Returns `true|false` depending on if given is found
```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: :nasty } } }

nasty_hash.deep_contains?(key: :nasty) # => true
nasty_hash.deep_contains?(key: :super_nasty) # => false
```

### Scoping
HashMiner supports partial updating of a hash based on the parent key.

Supported methods: 
- `deep_find`
- `deep_update`
- `deep_remove`

Pass through a `parent` key to any of these methods as either an `Array`|`String`|`Symbol` 

```ruby
require 'hash_miner'

nasty_hash = { my: { pretty: [{ nasty: :hash }, nil], is: { pretty: :nasty } } }

nasty_hash.deep_find(key: :pretty, parent: :is) # => [:nasty]
nasty_hash.deep_find(key: :pretty, parent: [:is]) # => [:nasty]
nasty_hash.deep_find(key: :pretty, parent: [:my, :is]) # => [{:nasty=>:hash}, nil, :nasty]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hash_miner.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
