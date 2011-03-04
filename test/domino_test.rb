require 'rubygems'
require 'minitest/autorun'
require 'minitest/mock'

gem 'minitest'
gem 'capybara'
gem 'nokogiri'
require File.join(File.dirname(__FILE__), '..', 'lib', 'domino')

class DominoTest < MiniTest::Unit::TestCase
  class StubbedDomino < ::Domino
    def self.page_body
      %{
        <html>
          <body>
            <h1>Here are people and animals</h1>
            <div id='people'>
              <div class='person'>
                <h2 class='name'>Alice</h2>
                <p class='bio'>Alice is fun</p>
                <p class='fav-color'>Blue</p>
              </div>
              <div class='person'>
                <h2 class='name'>Bob</h2>
                <p class='bio'>Bob is smart</p>
                <p class='fav-color'>Red</p>
              </div>
              <div class='person'>
                <h2 class='name'>Charlie</h2>
                <p class='bio'>Charlie is wild</p>
                <p class='fav-color'>Red</p>
              </div>
              <div class='person'>
                <h2 class='name'>Donna</h2>
                <p class='bio'>Donna is quiet</p>
              </div>
            </div>
            <div id='animals'></div>
            <div id='receipts'>
              <div class='receipt' id='receipt-72' data-store='ACME'></div>
            </div>
          </body>
        </html>
      }
    end
  end

  module Dom
    class Person < StubbedDomino
      selector '#people .person'
      attribute :name
      attribute :biography, '.bio'
      attribute :favorite_color, '.fav-color'
    end
    
    class Animal < StubbedDomino
      selector '#animals .animal'
      attribute :name
    end

    class Car < StubbedDomino
      selector '#cars .car'
    end

    class NoSelector < StubbedDomino
    end

    class Receipt < StubbedDomino
      selector '#receipts .receipt'
    end
  end
  
  def test_enumerable
    assert_equal 4, Dom::Person.count
    assert_equal 0, Dom::Animal.count
    assert_equal 0, Dom::Car.count

    assert_equal 4, Dom::Person.all.size

    red_people = Dom::Person.select{|p| p.favorite_color == 'Red'}
    assert_equal 2, red_people.count

    assert_equal(
      %w(Donna Alice Bob Charlie),  
      Dom::Person.sort{|a,b| 
        a.favorite_color.to_s <=> b.favorite_color.to_s
      }.map(&:name)
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

  def test_find_by_attribute_regex
    assert_equal 'Charlie', Dom::Person.find_by_biography(/wild/).name
  end

  def test_node_properties
    assert_equal 'ACME', Dom::Receipt.first.node['data-store']
  end
end
