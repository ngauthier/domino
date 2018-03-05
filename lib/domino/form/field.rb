class Domino::Form::Field
  attr_reader :name, :locator, :options, :callback

  def initialize(name, locator, options = {}, &callback)
    @name = name
    @locator = locator
    @options = options
    @callback = callback
    extract_field_options
  end

  # Delete any options for your field type that shouldn't be passed to
  # the field locator.
  # Default: noop
  def extract_field_options; end

  # Convert the value from `#read` via callback if provided.
  def value(node)
    val = read(node)
    if val && callback.is_a?(Proc)
      callback.call(val)
    else
      val
    end
  end

  # Locate the field using the locator and options
  def field(node)
    node.find_field(locator, options)
  end

  # Value that will be passed to the callback.
  # Default: field_node.value
  def read(node)
    field(node).value
  end

  # Sets the value on the field node.
  # Default: node.fill_in for text fields.
  def write(node, value)
    node.fill_in(locator, with: value, **options)
  end
end
