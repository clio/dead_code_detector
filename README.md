# DeadCodeDetector

DeadCodeDetector is a gem which finds code that hasn't been used in production environments so that it can be removed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dead_code_detector'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dead_code_detector

## How it works

DeadCodeDetector takes advantage of Ruby's ability to dynamically define methods. For each class that you want to track, it dynamically rewrites every method on that class to track its usage. Here's a simplified version of what it does:

```ruby
# Consider a class like this
class Foo
  def bar
    puts "hello world"
  end
end

# Once DeadCodeDetector wraps the methods (Part 3 - Enabling it) it might look like this
class Foo
  def bar
    begin
      DeadCodeDetector::InstanceMethodWrapper.track_method(Foo, :bar) # Track that this method was called
      Foo.define_method(:bar) do
        puts "hello world"
      end
    rescue
      # To ensure that if DeadCodeDetector breaks it doesn't break the existing code
    end
    puts "hello world"
  end
end

# That's how the method looks until it is hit once:
Foo.new.bar

# At this point we know that the method has been hit, so we restore the
# original version of the method.
```

Because DeadCodeDetector only records method calls once, the performance overhead at runtime is negligible.

DeadCodeDetector only tracks method calls and does not track which code is used inside the method. If that is what you are after, consider looking at [coverband](https://github.com/danmayer/coverband). It can track code usage at a more granular level, but it has its own tradeoffs.

## Usage

There are four steps to using DeadCodeDetector:

### Part 1 - Configuration

This is where you tell DeadCodeDetector what you want to do. In Rails, the configuration could live in `config/initializers`.

```ruby
DeadCodeDetector.configure do |config|
  # Two possible values:
  #   :memory - In-memory storage, not persisted anywhere else. Useful for test environments.
  #   :redis  - Data is stored as a set in Redis so that it is persisted across processes.
  # config.storage = :redis
  # config.storage = :memory

  # If using the `redis` storage option, this needs to be set.
  # config.redis = <instance of a Redis client object>

  # This controls whether DeadCodeDetector is enabled for this particular process, and takes either
  # a boolean or a object that responds to `call` that returns a boolean.
  # There is some overhead whenever DeadCodeDetector enables itself, so you might not want to enable
  # it on all of your processes.
  # config.allowed = true
  # config.allowed = -> { `hostname`.include?("01") }

  # DeadCodeDetector will filter out methods whose source_location matches this regular expression.
  # This is useful for filtering out methods from gems (such as the methods from ActiveRecord::Base)
  # config.ignore_paths = /\/vendor\//

  # A list of classes that DeadCodeDetector will monitor method usage on.
  # All descendants of these classes will be included.
  config.classes_to_monitor = [ActiveRecord::Base, ApplicationController]
end
```

### Part 2 - Cache Setup

Before DeadCodeDetector can do anything, it needs to calculate and store a list of methods that it's going to track. Call this method from a production console to initialize that database:

```ruby
DeadCodeDetector::Initializer.refresh_caches
```

If you add new classes or methods to your code which you want to track, you can call `refresh_caches` again at any time to clear all the accumulated data in Redis and start fresh. Until `refresh_caches` has been called at least once, DeadCodeDetector won't do anything.

### Part 3 - Enabling it

Wrap the code that you want to monitor in an `DeadCodeDetector.enable` block. Any code inside that block will record method calls in DeadCodeDetector's storage when they're called for the first time.

```ruby
DeadCodeDetector.enable do
  # Do some stuff
end
```

In Rails controllers, this could look like:
```ruby
around_perform :enable_dead_code_detector

def enable_dead_code_detector
  DeadCodeDetector.enable { yield }
end
```

### Part 4 - The Report

Once DeadCodeDetector has been running for a while, you can generate a report on what methods have not been called by calling `DeadCodeDetector::Report.unused_methods`

**Note**: This report doesn't say that methods are _never_ called, only that they _haven't_ been called. The longer DeadCodeDetector runs for, the more confident you can be that the method is unused.

Also, it's possible that some methods are being used, but are only called during the application boot process. DeadCodeDetector is unable to track those and may mis-report them as unused.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/clio/dead_code_detector. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DeadCodeDetector project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/clio/dead_code_detector/blob/master/CODE_OF_CONDUCT.md).
