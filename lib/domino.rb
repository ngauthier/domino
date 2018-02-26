require 'capybara/dsl'
require 'set'
# To create a basic Domino class, inherit from Domino and
# define a selector and attributes:
#
#     module Dom
#       class Post < Domino
#         selector '#posts .post'
#         attribute :title # selector defaults to .title
#         attribute :body, '.post-body' # example of selector override
#
#         # accepts blocks as callbacks these are run only if attribute exists
#         attribute :comments do |text|
#           text.to_i
#         end
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
  include Capybara::DSL
  extend  Capybara::DSL

  # Namespaced Domino::Error
  class Error < StandardError; end

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
      map { |node| node }
    end

    # Returns Domino for capybara node matching selector.
    #
    # Raises an error if no matching node is found. For drivers that
    # support asynchronous behavior, this method waits for a matching
    # node to appear.
    def find!
      require_selector!
      new(Capybara.current_session.find(@selector))
    end

    # Returns Domino for capybara node matching all attributes.
    def find_by(attributes)
      where(attributes).first
    end

    # Returns Domino for capybara node matching all attributes.
    #
    # Raises an error if no matching node is found.
    def find_by!(attributes)
      find_by(attributes) || raise(Capybara::ElementNotFound)
    end

    # Returns collection of Dominos for capybara node matching all attributes.
    def where(attributes)
      select do |node|
        attributes.all? do |key, value|
          node.send(key) == value if node.respond_to?(key)
        end
      end
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

    def attributes
      @attributes ||= []
    end

    def callbacks
      @callbacks ||= {}
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
    def attribute(attribute, selector = nil, &callback)
      attributes << attribute
      callbacks[attribute] = callback

      selector ||= %(.#{attribute.to_s.tr('_', '-')})

      class_eval %{
        def #{attribute}
          value = attribute(%{#{selector}})
          if value && self.class.callbacks[:#{attribute}].is_a?(Proc)
            self.class.callbacks[:#{attribute}].call(value)
          else
            value
          end
        end
        def self.find_by_#{attribute}(value)
          find_by_attribute(%{#{selector}}, value)
        end
      }
    end

    private

    # Return capybara nodes for this object
    def nodes
      require_selector!
      Capybara.current_session.all(@selector)
    end

    # Internal method for finding nodes by a selector
    def find_by_attribute(selector, value)
      detect do |node|
        if m = selector.match(/\A&(\S+)\z/)
          node.matches_css?(m[1])
        else
          value === node.attribute(selector)
        end
      end
    end

    def require_selector!
      raise Domino::Error, 'You must define a selector' if @selector.nil?
    end
  end

  # Get the text of the first dom element matching a selector
  #
  #   Dom::Post.all.first.attribute('.title')
  def attribute(selector)
    if m = selector.match(/^&(\S+)$/)
      attr = m[0].match(/(?<=\[).+?(?=\])/)[0]
      node[attr] || node.matches_css(selector)
    else
      node.find(selector).text
    end
  rescue Capybara::ElementNotFound
    nil
  end

  # Dom id for this object.
  def id
    node['id'].nil? ? nil : %(##{node['id']})
  end

  def attributes
    self.class.attributes.each_with_object({}) do |attribute, memo|
      memo[attribute] = send(attribute)
    end
  end

  private

  # Store the capybara node internally
  def initialize(node)
    @node = node
  end
end
