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
#         # can define attributes on the selected node
#         attribute :uuid, "&[data-uuid]"
#
#         # can define states based on classes of the selected node
#         attribute :active, "&.active"
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
      map { |domino| domino }
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
      select do |domino|
        attributes.all? do |key, value|
          domino.send(key) == value if domino.respond_to?(key)
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
      attribute_definitions.keys
    end

    def attribute_definitions
      @attribute_definitions ||= {}
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
      selector ||= %(.#{attribute.to_s.tr('_', '-')})

      attribute_definitions[attribute] = Attribute.new(attribute, selector, &callback)

      define_method :"#{attribute}" do
        self.class.attribute_definitions[attribute].value(node)
      end

      define_singleton_method :"find_by_#{attribute}" do |value|
        find_by_attribute(attribute, value)
      end
    end

    private

    # Return capybara nodes for this object
    def nodes
      require_selector!
      Capybara.current_session.all(@selector)
    end

    # Internal method for finding nodes by a selector
    def find_by_attribute(attribute, value)
      detect do |domino|
        attribute_definitions[attribute].match_value?(domino.node, value)
      end
    end

    def require_selector!
      raise Domino::Error, 'You must define a selector' if @selector.nil?
    end
  end

  # Get the text of the first dom element matching a selector:
  #
  #   Dom::Post.all.first.attribute('.title')
  #
  # Or get the value of the attribute of this dom element:
  #
  #   Dom::Post.all.first.attribute('&[href]')
  def attribute(selector, &callback)
    Attribute.new(nil, selector, &callback).value(node)
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

  class Form < Domino
    class Field
      attr_reader :name, :locator, :options, :callback

      def initialize(name, locator, options = {}, &callback)
        @name = name
        @locator = locator
        @options = options
        @callback = callback
      end

      def value(node)
        val = read(node)
        if val && callback.is_a?(Proc)
          callback.call(val)
        else
          val
        end
      end

      def read(node)
        node.find_field(locator, options).value
      end

      def write(node, value)
        node.fill_in(locator, with: value, **options)
      end
    end

    class SelectField < Field
      def write(node, value)
        node.select value, from: locator
      end
    end

    class BooleanField < Domino::Form::Field
      def read(node)
        node.find_field(locator, options).checked?
      end

      def write(node, value)
        if value
          node.check(locator, options)
        else
          node.uncheck(locator, options)
        end
      end
    end

    FIELD_TYPES = {
      select: SelectField,
      boolean: BooleanField
    }.freeze

    def self.key(k)
      @key = k
    end

    def self.fields
      @fields ||= {}
    end

    def self.field(*args, &callback)
      options = args.last.is_a?(::Hash) ? args.pop : {}
      attribute, locator = *args

      locator ||= !@key.to_s.empty? ? "#{@key}[#{attribute}]" : attribute

      field_type = options.delete(:as)
      field_class = field_type.is_a?(Class) && field_type.ancestors.include?(Field) ? field_type : FIELD_TYPES[field_type] || Field

      fields[attribute] = field_class.new(attribute, locator, options, &callback)

      define_method :"#{attribute}" do
        self.class.fields[attribute].value(node)
      end

      define_method :"#{attribute}=" do |value|
        self.class.fields[attribute].write(node, value)
      end
    end

    def self.create(attributes = {})
      first.create(attributes)
    end

    def self.update(attributes = {})
      first.update(attributes)
    end

    def create(attributes = {})
      set(attributes)
      save
    end

    def update(attributes = {})
      set(attributes)
      save
    end

    def set(attributes = {})
      attributes.each { |k, v| send("#{k}=", v) }
    end

    def save
      find('input[name="commit"]').click
    end
  end

  private

  # Store the capybara node internally
  def initialize(node)
    @node = node
  end

  class Attribute
    attr_reader :name, :selector, :callback

    def initialize(name, selector = nil, &callback)
      @callback = callback
      @name = name
      @selector = selector || %(.#{name.to_s.tr('_', '-')})
    end

    def value(node)
      val = value_before_typecast(node)

      if val && callback.is_a?(Proc)
        callback.call(val)
      else
        val
      end
    end

    # Get the text of the first dom element matching a selector
    #
    #   Dom::Post.all.first.attribute('.title')
    def value_before_typecast(node)
      if combinator?
        node[node_attribute_key] || node.matches_css?(combinator)
      else
        node.find(selector).text
      end
    rescue Capybara::ElementNotFound
      nil
    end

    def match_value?(node, value)
      value === value(node)
    end

    private

    def combinator?
      selector[0] == '&'.freeze
    end

    def combinator
      @combinator ||= selector.sub(/&/, '') if combinator?
    end

    def node_attribute_key
      @node_attribute_key ||= combinator.match(/(?<=\[).+?(?=\])/) { |m| m[0] }
    end
  end
end
