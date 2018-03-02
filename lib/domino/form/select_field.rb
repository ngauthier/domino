class Domino::Form::SelectField < Domino::Form::Field
  attr_reader :value_source

  def extract_field_options
    @value_source = options.delete(:source) || :value
  end

  def read(node)
    node.find_field(locator, options)
  end

  def write(node, value)
    s = node.find_field(locator, options)
    values = Array(value)

    s.all('option').each do |o|
      if values.include?(o.text) || values.include?(o.value)
        o.select_option
      elsif s.multiple?
        o.unselect_option
      end
    end
  end

  def callback
    @callback ||= Proc.new do |node|
      case value_source
      when :text
        selected = node.all("option[selected]").map(&:text)
        node.multiple? ? selected : selected.first
      else
        node.value
      end
    end
  end
end
