# Domino

View abstraction for integration testing

## Usage

To create a basic Domino class, inherit from Domino and
define a selector and attributes:

    module Dom
      class Post < Domino
        selector '#posts .post'
        attribute :title # selector defaults to .title
        attribute :body, '.post-body' # example of selector override
      end
    end

In some cases, you may want to use this node's text as an attribute


    module Dom
      class Artist < Domino
        selector '#artists .artist'
        attribute :title, "." # Use this node's text as a title
      end
    end


Now in your integration test you can use some of Domino's methods:

    assert_equal 4, Dom::Post.count
    refute_nil Dom::Post.find_by_title('First Post')

What makes it really powerful is defining scoped actions:

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

## Integration with Cucumber

Add a features/support/dominos.rb file, in which you define your dominos.

Use them in your steps.

## Integration with Test::Unit

Include "domino" in your Gemfile if using bundler, or simply

    require 'domino'

If you're not using Bundler.

Now, define your Dominos anywhere you want. The easiest place to start is
in your test\_helper.rb (doesn't have to be inside a Rails test class).

## Example

Check out [Domino Example](http://github.com/ngauthier/domino_example) for an
example of using Test::Unit and Cucumber with Domino.

## Copyright

Copyright (c) 2011 Nick Gauthier, released under the MIT license
