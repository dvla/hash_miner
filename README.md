# HashMiner

Ever experienced the pain of working with deeply nested hashes in Ruby? 

HashMiner expands the base Hash class in Ruby to provide helpful methods to traverse your Hash Object regardless of complexity.

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

### Methods available
#### deep_update
#### deep_remove
#### deep_find
#### deep_compact
#### deep_count
#### deep_contains?

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hash_miner.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
