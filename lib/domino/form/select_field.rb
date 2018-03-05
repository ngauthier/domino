class Domino::Form::SelectField < Domino::Form::Field
  # Returns the set of selected options that can be processed in the callback.
  def read(node)
    s = field(node)
    selected = s.all('option[selected]')
    s.multiple? ? selected : selected.first
  end

  def write(node, value)
    s = field(node)
    values = Array(value)

    s.all('option').each do |o|
      if values.include?(o.text) || values.include?(o.value)
        o.select_option
      elsif s.multiple?
        o.unselect_option
      end
    end
  end

  def value(node)
    val = read(node)
    return val unless callback
    if field(node).multiple?
      val.map { |opt| callback.call(opt) }
    else
      callback.call(val)
    end
  end

  # Any callback mapping on a select will recieve one or more option nodes.
  # Applying to one item or an Enumerable.
  def callback
    @callback ||= :value.to_proc
  end
end
