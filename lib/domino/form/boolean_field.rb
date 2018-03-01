class Domino::Form::BooleanField < Domino::Form::Field
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
