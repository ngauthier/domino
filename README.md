# Domino [![Build Status](https://travis-ci.org/ngauthier/domino.png?branch=master)](https://travis-ci.org/ngauthier/domino)

View abstraction for integration testing

## Usage

To create a basic Domino class, inherit from Domino and
define a selector and attributes:

```ruby
module Dom
  class Post < Domino
    selector '#posts .post'
    attribute :title # selector defaults to .title
    attribute :author_name # selector defaults to .author-name
    attribute :body, '.post-body' # example of selector override

    # pass a block if you want to modify the value
    attribute :comments do |text|
      text.to_i
    end

    attribute :posted_at do |text|
      Date.parse(text)
    end
  end
end
```

Now in your integration test you can use some of Domino's methods:

```ruby
assert_equal 4, Dom::Post.count
refute_nil Dom::Post.find_by_title('First Post')

# Multiple attributes, returns first match if any
refute_nil Dom::Post.find_by(title: 'First Post', author: 'Jane Doe')

# Multiple attributes with exception if no match is found
refute_nil Dom::Post.find_by!(title: 'First Post', author: 'Jane Doe')

# Multiple attributes, returns all matches if any
assert_equal ["12/06/2014", "12/01/2014"], Dom::Post.where(author: 'Jane Doe').map(&:posted_on)
```

What makes it really powerful is defining scoped actions:

```ruby
module Dom
  class Post < Domino
    def delete
      within(id) { click_button 'Delete' }
    end
  end
end

refute_nil Dom::Post.find_by_title('First Post')
Dom::Post.find_by_title('First Post').delete
assert_nil Dom::Post.find_by_title('First Post')
```

## Integration with capybara

Domino uses capybara internally to search html for nodes and
attributes. If you need to do something special, you can have direct
access to the capybara node.

```ruby
module Dom
  class Account < Domino
    selector "#accounts li"
    # Returns this node text
    def text
        node.text
    end
  end
end
```

For more information about using Capybara nodes, check [Capybara Documentation](https://github.com/jnicklas/capybara/blob/master/README.rdoc).

## Dealing with Asynchronous Behavior

When working with Capybara drivers that support JavaScript, it may be
necessary to wait for elements to appear. Note that the following code
simply collects all `Account` dominos currently on the page and
returns the first:

```ruby
Dom::Account.first # returns nil if account is displayed asynchronously
```

When you are waiting for a unique domino to appear, you can instead
use the `find!` method:

```ruby
Dom::Account.find! # waits for matching element to appear
```

If no matching element appears, Capybara will raise an error telling
you about the expected selector.  Depending on the
[`Capybara.match` option](https://github.com/jnicklas/capybara#strategy),
this will also raise an error if the selector matches multiple nodes.

## Integration with Cucumber

Add a features/support/dominos.rb file, in which you define your dominos.

Use them in your steps.

## Integration with Test::Unit

Include "domino" in your Gemfile if using bundler, or simply

```ruby
require 'domino'
```

If you're not using Bundler.

Now, define your Dominos anywhere you want. The easiest place to start is
in your test\_helper.rb (doesn't have to be inside a Rails test class).

## Example

Check out [Domino Example](http://github.com/ngauthier/domino_example) for an
example of using Test::Unit and Cucumber with Domino.

## Copyright

Copyright (c) 2011 Nick Gauthier, released under the MIT license
