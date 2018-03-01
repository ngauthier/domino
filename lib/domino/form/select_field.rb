class Domino::Form::SelectField < Domino::Form::Field
  def write(node, value)
    node.select value, from: locator
  end
end
