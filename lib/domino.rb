require 'capybara/dsl'
# To create a basic Domino class, inherit from Domino and
# define a selector and attributes:
#
#     module Dom
#       class Post < Domino
#         selector '#posts .post'
#         attribute :title # selector defaults to .title
#         attribute :body, '.post-body' # example of selector override
#       end
#     end
#
# Now in your integration test you can use some of Domino's methods:
#
#     assert_equal 4, Dom::Post.count
#     refute_nil Dom::Post.find_by_title('First Post')
#
# What makes it really powerful is defining scoped actions:
#
#     module Dom
#       class Post < Domino
#         def delete
#           within(id) { click_button 'Delete' }
#         end
#       end
#     end
#
#     refute_nil Dom::Post.find_by_title('First Post')
#     Dom::Post.find_by_title('First Post').delete
#     assert_nil Dom::Post.find_by_title('First Post')
class Domino
  include Capybara
  extend  Capybara

  # Namespaced Domino::Error
  class Error < StandardError ; end

  # Direct access to the capybara node, in case you need
  # anything special
  attr_reader :node

  class << self
    include Enumerable

    # Iterate over all the Dominos
    def each
      nodes.each do |node|
        yield new(node)
      end
    end

    # Get an array of all the Dominos
    def all
      map{|node| node}
    end

    # Define the selector for this Domino
    #
    #   module Dom
    #     class Post
    #       selector '#posts .post'
    #     end
    #   end
    def selector(s)
      @selector = s
    end

    # Define an attribute for this Domino
    #
    #   module Dom
    #     class Post
    #       attribute :title # defaults to selector '.title'
    #       attribute :body, '.post-body' # use a custom selector
    #     end
    #   end
    #
    # This will define an attr_reader on the Domino
    # and also a find_by_attribute method:
    #
    #   Dom::Post.all.first.title
    #   Dom::Post.find_by_title("First Post")
    #   Dom::Post.find_by_title(/^First/)
    def attribute(attribute, selector = nil)
      selector ||= %{.#{attribute.to_s}}

      class_eval %{
        def #{attribute}
          attribute(%{#{selector}})
        end
        def self.find_by_#{attribute}(value)
          find_by_attribute(%{#{selector}}, value)
        end
      }
    end

    private

    # Return capybara nodes for this object
    def nodes
      if @selector.nil?
        raise Domino::Error.new("You must define a selector")
      end
      Capybara.current_session.all(@selector)
    end

    # Internal method for finding nodes by a selector 
    def find_by_attribute(selector, value)
      case value
      when Regexp
        detect{|node| node.attribute(selector) =~ value }
      else
        detect{|node| node.attribute(selector) == value }
      end
    end
  end

  # Get the text of the first dom element matching a selector
  #
  #   Dom::Post.all.first.attribute('.title')
  def attribute(selector)
    @node.find(selector).text
  rescue Capybara::ElementNotFound
    nil
  end

  # Dom id for this object.
  def id
    @node['id'].nil? ? nil : %{##{@node['id']}}
  end

  private
  # Store the capybara node internally
  def initialize(node)
    @node = node
  end
end
