class Domino::Form::SelectField < Domino::Form::Field
  def write(node, value)
    s = node.find_field(locator, options)
    values = Array(value)
    values.each do |val|
      s.select val
    end

    if s.multiple?
      s.all('option').reject { |o| values.include?(o.text) }.each do |o|
        s.unselect o.text
      end
    end
  end
end
