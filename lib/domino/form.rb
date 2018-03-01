class Domino::Form < Domino
  require 'domino/form/field'
  require 'domino/form/select_field'
  require 'domino/form/boolean_field'

  FIELD_TYPES = {
    select: SelectField,
    boolean: BooleanField
  }.freeze

  def self.key(k)
    @key = k
  end

  def self.fields
    @fields ||= {}
  end

  def self.field(*args, &callback)
    options = args.last.is_a?(::Hash) ? args.pop : {}
    attribute, locator = *args

    locator ||= !@key.to_s.empty? ? "#{@key}[#{attribute}]" : attribute

    field_type = options.delete(:as)
    field_class = field_type.is_a?(Class) && field_type.ancestors.include?(Field) ? field_type : FIELD_TYPES[field_type] || Field

    fields[attribute] = field_class.new(attribute, locator, options, &callback)

    define_method :"#{attribute}" do
      self.class.fields[attribute].value(node)
    end

    define_method :"#{attribute}=" do |value|
      self.class.fields[attribute].write(node, value)
    end
  end

  def self.create(attributes = {})
    first.create(attributes)
  end

  def self.update(attributes = {})
    first.update(attributes)
  end

  def create(attributes = {})
    set(attributes)
    save
  end

  def update(attributes = {})
    set(attributes)
    save
  end

  def set(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end

  def save
    find('input[name="commit"]').click
  end
end
