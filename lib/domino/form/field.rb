class Domino::Form::Field
  attr_reader :name, :locator, :options, :callback

  def initialize(name, locator, options = {}, &callback)
    @name = name
    @locator = locator
    @options = options
    @callback = callback
    extract_field_options
  end

  def extract_field_options
    # nothing here, but can be overridden to extract options for the field
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
