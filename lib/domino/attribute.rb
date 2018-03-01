class Domino::Attribute
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
