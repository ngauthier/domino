class DominoFormTest < Minitest::Test
  include Capybara::DSL

  module Dom
    class CheckBoxesField < Domino::Form::Field
      def read(node)
        node.find(locator).all('input[type=checkbox]').select(&:checked?).map(&:value)
      end

      def write(node, value)
        value = Array(value)
        node.find(locator).all('input[type=checkbox]').each do |box|
          box.set(value.include?(box.value))
        end
      end
    end

    class PersonForm < Domino::Form
      selector 'form.person'
      key 'person'

      field :name, 'First Name'
      field :last_name
      field :biography, 'person[bio]'
      field :favorite_color, 'Favorite Color', as: :select, &:text
      field :age, 'person_age', &:to_i
      field :vehicles, '.input.vehicles', as: CheckBoxesField
      field :is_human, 'is_human', as: :boolean

      attribute :action, '&[action]'
      attribute :submit_method, '&[method]'
    end

    class PersonFormB < Domino::Form
      selector 'form.person'

      field :is_human, as: :boolean
      field :allergies, as: :select
    end
  end

  def setup
    visit '/people/23/edit'
  end

  def test_form_field_with_label_locator
    assert_equal 'Alice', Dom::PersonForm.find!.name
  end

  def test_form_field_with_default_locator_and_form_key
    assert_equal 'Cooper', Dom::PersonForm.find!.last_name
  end

  def test_form_field_with_name_locator
    assert_equal 'Alice is fun', Dom::PersonForm.find!.biography
  end

  def test_form_field_as_select_field_type
    assert_equal 'Blue', Dom::PersonForm.find!.favorite_color
  end

  def test_form_field_as_multiple_select_field_type
    formb = Dom::PersonFormB.find!
    assert_equal [], formb.allergies
    formb.allergies = %w[Peanut Corn]
    assert_equal %w[peanut corn], formb.allergies
    formb.allergies = ['corn']
    assert_equal ['corn'], formb.allergies
  end

  def test_form_field_with_id_locator_and_callback
    assert_equal 23, Dom::PersonForm.find!.age
  end

  def test_form_field_with_custom_field_type
    assert_equal [], Dom::PersonForm.find!.vehicles
  end

  def test_form_field_with_boolean_field_type
    assert_equal false, Dom::PersonForm.find!.is_human
  end

  def test_form_set_multiple_attributes
    person = Dom::PersonForm.find!
    person.set name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Red', age: 25, vehicles: %w[Bike Car], is_human: true

    assert_equal 'Marie', person.name
    assert_equal 'Curie', person.last_name
    assert_equal 'Scientific!', person.biography
    assert_equal 'Red', person.favorite_color
    assert_equal 25, person.age
    assert_equal %w[Bike Car], person.vehicles
    assert_equal true, person.is_human
  end

  def test_form_fields
    person = Dom::PersonForm.find!
    assert_equal({ name: 'Alice', last_name: 'Cooper', biography: 'Alice is fun', favorite_color: 'Blue', age: 23, vehicles: [], is_human: false }, person.fields)
  end

  def test_form_set_nil_clears_field
    person = Dom::PersonForm.find!
    person.name = nil
    assert_equal '', person.name
  end

  def test_form_set_by_attribute_writer
    person = Dom::PersonForm.find!
    assert_equal 23, person.age
    person.age = 66
    assert_equal 66, person.age
  end

  def test_form_default_selector_without_key
    formb = Dom::PersonFormB.find!
    assert_equal false, formb.is_human
    formb.is_human = true
    assert_equal true, formb.is_human
    formb.is_human = false
    assert_equal false, formb.is_human
  end

  def test_save_submits_form
    person = Dom::PersonForm.find!
    refute page.has_content?('Person updated successfully.')

    person.set name: 'Marie', last_name: 'Curie', biography: 'Scientific!', age: 25, favorite_color: 'Green', vehicles: %w[Bike Car], is_human: true

    person.save

    assert page.has_content?('Person updated successfully.')

    updated_person = Dom::PersonForm.find!
    assert_equal 'Marie', updated_person.name
    assert_equal 'Curie', updated_person.last_name
    assert_equal 'Scientific!', updated_person.biography
    assert_equal 'Green', updated_person.favorite_color
    assert_equal 25, updated_person.age
    assert_equal %w[Bike Car], updated_person.vehicles
    assert_equal true, updated_person.is_human
  end

  def test_update_fills_and_submits_form
    person = Dom::PersonForm.find!
    refute page.has_content?('Person updated successfully.')

    person.update name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true

    assert page.has_content?('Person updated successfully.')

    updated_person = Dom::PersonForm.find!
    assert_equal({ name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true }, updated_person.fields)
  end

  def test_create_fills_and_submits_form
    person = Dom::PersonForm.find!
    refute page.has_content?('Person updated successfully.')

    person.create name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true

    assert page.has_content?('Person updated successfully.')

    updated_person = Dom::PersonForm.find!
    assert_equal({ name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true }, updated_person.fields)
  end

  def test_static_update_fills_and_submits_form
    refute page.has_content?('Person updated successfully.')

    Dom::PersonForm.create name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true

    assert page.has_content?('Person updated successfully.')

    updated_person = Dom::PersonForm.find!
    assert_equal({ name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true }, updated_person.fields)
  end

  def test_static_create_fills_and_submits_form
    refute page.has_content?('Person updated successfully.')

    Dom::PersonForm.create name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true

    assert page.has_content?('Person updated successfully.')

    updated_person = Dom::PersonForm.find!
    assert_equal({ name: 'Marie', last_name: 'Curie', biography: 'Scientific!', favorite_color: 'Green', age: 25, vehicles: %w[Bike Car], is_human: true }, updated_person.fields)
  end

  def test_static_create_with_no_matches
    visit '/'
    assert_raises Capybara::ElementNotFound do
      Dom::PersonForm.create name: 'Marie', last_name: 'Curie'
    end
  end

  def test_static_update_with_no_matches
    visit '/'
    assert_raises Capybara::ElementNotFound do
      Dom::PersonForm.update name: 'Marie', last_name: 'Curie'
    end
  end

  def test_supports_normal_attributes
    assert_equal({ action: '/people/23', submit_method: 'post' }, Dom::PersonForm.find!.attributes)
  end

  def test_named_field_method_yields_node
    person = Dom::PersonForm.find!
    name_field_node = page.find_field('First Name')
    assert_equal(name_field_node, person.name { |node| node })
    person.name { |node| node }
  end

  def test_named_field_yield_usefulness
    person = Dom::PersonForm.find!
    assert_equal ['- Select a Color -', 'Red', 'Blue', 'Green'], person.favorite_color { |n| n.all('option').map(&:text) }
  end
end
