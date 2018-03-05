class DominoTest < Minitest::Test
  include Capybara::DSL

  module Dom
    class Person < Domino
      selector '#people .person'

      attribute :name
      attribute :last_name
      attribute :biography, '.bio'
      attribute :favorite_color, '.fav-color'
      attribute :age, &:to_i
      attribute :rank, '&[data-rank]', &:to_i
      attribute :active, '&.active'
      attribute :uuid, '&[data-uuid]'
      attribute(:blocked, '&[data-blocked]') { |a| !a.nil? }
    end

    class Animal < Domino
      selector '#animals .animal'
      attribute :name
    end

    class Car < Domino
      selector '#cars .car'
    end

    class NoSelector < Domino
    end

    class Receipt < Domino
      selector '#receipts .receipt'
    end
  end

  def setup
    visit '/'
  end

  def test_enumerable
    assert_equal 4, Dom::Person.count
    assert_equal 0, Dom::Animal.count
    assert_equal 0, Dom::Car.count

    assert_equal 4, Dom::Person.all.size

    red_people = Dom::Person.select { |p| p.favorite_color == 'Red' }
    assert_equal 2, red_people.count

    assert_equal(
      %w[Donna Alice Bob Charlie],
      Dom::Person.sort do |a, b|
        a.favorite_color.to_s <=> b.favorite_color.to_s
      end.map(&:name)
    )
  end

  def test_no_selector
    assert_raises Domino::Error do
      Dom::NoSelector.first
    end
  end

  def test_no_id
    assert_nil Dom::Person.first.id
  end

  def test_id
    assert_equal '#receipt-72', Dom::Receipt.first.id
  end

  def test_find_by_attribute_string
    assert_equal 'Alice', Dom::Person.find_by_biography('Alice is fun').name
  end

  def test_default_selector
    assert_equal 'Cooper', Dom::Person.find_by_name('Alice').last_name
  end

  def test_find_by_attribute_regex
    assert_equal 'Charlie', Dom::Person.find_by_biography(/wild/).name
  end

  def test_find_by_data_combinator_attribute_regex
    assert_equal 'Charlie', Dom::Person.find_by_uuid(/abcdef/).name
  end

  def test_node_properties
    assert_equal 'ACME', Dom::Receipt.first.node['data-store']
  end

  def test_attributes
    assert_equal({ name: 'Alice', last_name: 'Cooper', biography: 'Alice is fun', favorite_color: 'Blue', age: 23, rank: 1, active: true, uuid: 'e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f', blocked: false }, Dom::Person.first.attributes)
  end

  def test_callback
    assert_equal 23, Dom::Person.find_by_name('Alice').age
  end

  def test_find_bang
    assert_equal '#receipt-72', Dom::Receipt.find!.id
  end

  def test_find_bang_without_match
    assert_raises Capybara::ElementNotFound do
      Dom::Animal.find!
    end
  end

  def test_find_bang_without_selector
    assert_raises Domino::Error do
      Dom::NoSelector.find!
    end
  end

  def test_find_by
    assert_equal 'Alice', Dom::Person.find_by(biography: 'Alice is fun').name
  end

  def test_find_by_with_multiple_attributes
    assert_equal 'Alice', Dom::Person.find_by(biography: 'Alice is fun', age: 23, favorite_color: 'Blue', rank: 1).name
  end

  def test_find_by_without_match
    assert_nil Dom::Person.find_by(foo: 'bar')
  end

  def test_find_by_without_selector
    assert_raises Domino::Error do
      Dom::NoSelector.find_by(foo: 'bar')
    end
  end

  def test_find_by_class_combinator_attribute
    assert_equal 'Alice', Dom::Person.find_by(active: true).name
  end

  def test_find_by_data_key_combinator_attribute
    assert_equal 'Donna', Dom::Person.find_by(blocked: true).name
  end

  def test_find_by_data_combinator_attribute
    assert_equal 'Charlie', Dom::Person.find_by(rank: 2).name
  end

  def test_find_by_bang
    assert_equal 'Alice', Dom::Person.find_by!(biography: 'Alice is fun').name
  end

  def test_find_by_bang_with_multiple_attributes
    assert_equal 'Alice', Dom::Person.find_by!(biography: 'Alice is fun', age: 23, favorite_color: 'Blue', rank: 1).name
  end

  def test_find_by_bang_without_selector
    assert_raises Domino::Error do
      Dom::NoSelector.find_by(foo: 'bar')
    end
  end

  def test_find_by_bang_without_match
    assert_raises Capybara::ElementNotFound do
      Dom::Person.find_by!(foo: 'bar')
    end
  end

  def test_where_with_single_attribute
    assert_equal %w[Bob Charlie], Dom::Person.where(favorite_color: 'Red').map(&:name)
  end

  def test_where_with_multiple_attributes
    assert_equal %w[Alice], Dom::Person.where(age: 23, favorite_color: 'Blue').map(&:name)
  end

  def test_where_with_class_combinator_attribute
    assert_equal %w[Bob Charlie Donna], Dom::Person.where(active: false).map(&:name)
  end

  def test_where_with_data_key_combinator_attribute
    assert_equal %w[Donna], Dom::Person.where(blocked: true).map(&:name)
  end

  def test_where_without_match
    assert_equal [], Dom::Person.where(favorite_color: 'Yellow')
  end

  def test_where_without_selector
    assert_raises Domino::Error do
      Dom::NoSelector.where(foo: 'bar')
    end
  end

  def test_named_field_method_yields_node
    person = Dom::Person.find_by!(uuid: 'e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f')
    name_node = page.find(".person[data-uuid='e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f'] .name")
    assert_equal(name_node, person.name { |node| node })
  end

  def test_named_field_method_yields_node_when_combinator
    person = Dom::Person.find_by!(uuid: 'e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f')
    uuid_node = page.find(".person[data-uuid='e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f']")
    assert_equal(uuid_node, person.uuid { |node| node })
  end

  def test_named_field_yield_usefulness
    person = Dom::Person.find_by!(uuid: 'e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f')
    assert_equal 'h2', person.name(&:tag_name)
  end

  def test_find_by_with_unconverted_value_for_callback_computed_attribute
    person = Dom::Person.find_by!(uuid: '05bf319e-8d6a-43c2-be37-2dad8ddbe5af')
    assert_equal person.node, Dom::Person.find_by_age('52').node
  end

  def test_find_by_with_converted_value_for_callback_computed_attribute
    person = Dom::Person.find_by!(uuid: '05bf319e-8d6a-43c2-be37-2dad8ddbe5af')
    assert_equal person.node, Dom::Person.find_by_age(52).node
  end

  def test_find_by_with_converted_value_for_callback_computed_attribute_with_regex
    person = Dom::Person.find_by!(uuid: '05bf319e-8d6a-43c2-be37-2dad8ddbe5af')
    assert_equal person.node, Dom::Person.find_by_age { |age_node| age_node.text =~ /5[29]/ && age_node.tag_name == 'p' }.node
  end
end
