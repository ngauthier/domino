require 'bundler/setup'
unless ENV['CI']
  require 'simplecov'
  SimpleCov.start
end
Bundler.require
require 'minitest/autorun'
require 'minitest/mock'

class TestApplication
  def call(env)
    [200, { 'Content-Type' => 'text/plain' }, [response(env)]]
  end

  def response(env)
    case env.fetch('PATH_INFO')
    when '/'
      root
    when '/people/1/edit'
      edit
    end
  end

  def root
    <<-HTML
      <html>
        <body>
          <h1>Here are people and animals</h1>
          <div id='people'>
            <div class='person active' data-rank="1" data-uuid="e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f">
              <h2 class='name'>Alice</h2>
              <p class='last-name'>Cooper</p>
              <p class='bio'>Alice is fun</p>
              <p class='fav-color'>Blue</p>
              <p class='age'>23</p>
            </div>
            <div class='person' data-rank="3" data-uuid="05bf319e-8d6a-43c2-be37-2dad8ddbe5af">
              <h2 class='name'>Bob</h2>
              <p class='last-name'>Marley</p>
              <p class='bio'>Bob is smart</p>
              <p class='fav-color'>Red</p>
              <p class='age'>52</p>
            </div>
            <div class='person' data-rank="2" data-uuid="4abcdeff-1d36-44a9-a05e-8fc57564d2c4">
              <h2 class='name'>Charlie</h2>
              <p class='last-name'>Murphy</p>
              <p class='bio'>Charlie is wild</p>
              <p class='fav-color'>Red</p>
            </div>
            <div class='person' data-rank="7" data-blocked data-uuid="2afccde0-5d13-41c7-ab01-7f37fb2fe3ee">
              <h2 class='name'>Donna</h2>
              <p class='last-name'>Summer</p>
              <p class='bio'>Donna is quiet</p>
            </div>
          </div>
          <div id='animals'></div>
          <div id='receipts'>
            <div class='receipt' id='receipt-72' data-store='ACME'></div>
          </div>
        </body>
      </html>
    HTML
  end

  def edit
    <<-HTML
      <html>
        <body>
          <h1>Edit Person</h1>

          <form action="/person/23" method="post" class="person">
            <div class="input name">
              <label for="person_name">First Name</label>
              <input type="text" id="person_name" name="person[name]" value="Alice" />
            </div>

            <div class="input last_name">
              <label for="person_name">Last Name</label>
              <input type="text" id="person_last_name" name="person[last_name]" value="Cooper" />
            </div>

            <div class="input bio">
              <label for="person_bio">Biography</label>
              <textarea id="person_bio" name="person[bio]">Alice is fun</textarea>
            </div>

            <div class="input fav_color">
              <label for="person_fav_color">Favorite Color</label>
              <select id="person_fav_color" name="person[fav_color]">
                <option val="red">Red</option>
                <option val="blue" selected>Blue</option>
                <option val="green">Green</option>
              </select>
            </div>

            <div class="input age">
              <label for="person_age">Biography</label>
              <input type="number" min="0" step="1" id="person_age" name="person[age]" value="23" />
            </div>

            <div class="input vehicles">
              <label for="person_vehicles_bike"><input id="person_vehicles_bike" type="checkbox" name="person[vehicles][]" value="Bike">Bike</label>
              <label for="person_vehicles_car"><input id="person_vehicles_car" type="checkbox" name="person[vehicles][]" value="Car">Car</label>
            </div>

            <div class="actions">
              <input type="submit" name="commit" value="Update Person" />
            </div>
          </form>
        </body>
      </html>
    HTML
  end
end

Capybara.app = TestApplication.new

class DominoTest < MiniTest::Unit::TestCase
  include Capybara::DSL

  module Dom
    class CheckBoxField < Domino::Form::Field
      def read(node)
        node.find(locator).all("input[type=checkbox]").select{|c| c.checked? }.map(&:value)
      end

      def write(node, value)
        value = Array(value)
        node.find(locator).all("input[type=checkbox]").each do |box|
          box.set(value.include?(box.value))
        end
      end
    end

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

      class Form < Domino::Form
        selector 'form.person'
        key 'person'

        field :name, 'First Name'
        field :last_name
        field :biography, 'person[bio]'
        field :favorite_color, 'Favorite Color', type: :select
        field :age, 'person_age'
        field :vehicles, '.input.vehicles', using: CheckBoxField
      end
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

  def test_form
    visit '/people/1/edit'

    form = Dom::Person::Form.find!

    assert_equal 'Alice', form.name
    assert_equal 'Cooper', form.last_name
    assert_equal 'Alice is fun', form.biography
    assert_equal 'Blue', form.favorite_color
    assert_equal '23', form.age
    assert_equal [], form.vehicles

    form.set name: 'Marie', last_name: 'Curie', biography: 'Scientific!', age: 25, favorite_color: "Red", vehicles: ["Bike", "Car"]

    assert_equal 'Marie', form.name
    assert_equal 'Curie', form.last_name
    assert_equal 'Scientific!', form.biography
    assert_equal 'Red', form.favorite_color
    assert_equal '25', form.age
    assert_equal ["Bike", "Car"], form.vehicles
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
end
