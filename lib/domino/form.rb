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
    field_definitions.keys
  end

  def self.field_definitions
    @field_definitions ||= {}
  end

  def self.submit_with(submitter)
    @submitter = submitter
  end

  def self.submitter
    @submitter ||= "input[type='submit']"
  end

  def self.field(*args, &callback)
    options = args.last.is_a?(::Hash) ? args.pop : {}
    attribute, locator = *args

    locator ||= !@key.to_s.empty? ? "#{@key}[#{attribute}]" : attribute

    field_type = options.delete(:as)
    field_class = field_type.is_a?(Class) && field_type.ancestors.include?(Field) ? field_type : FIELD_TYPES[field_type] || Field

    field_definitions[attribute] = field_class.new(attribute, locator, options, &callback)

    define_method :"#{attribute}" do |&block|
      if block.is_a?(Proc)
        block.call(self.class.field_definitions[attribute].field(node))
      else
        self.class.field_definitions[attribute].value(node)
      end
    end

    define_method :"#{attribute}=" do |value|
      self.class.field_definitions[attribute].write(node, value)
    end
  end

  def self.create(attributes = {})
    find!.create(attributes)
  end

  def self.update(attributes = {})
    find!.update(attributes)
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
    find(self.class.submitter).click
  end

  def fields
    self.class.fields.each_with_object({}) do |field, memo|
      memo[field] = send(field)
    end
  end
end
