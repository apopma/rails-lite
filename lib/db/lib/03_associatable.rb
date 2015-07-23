require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
  )

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    class_name.downcase + 's'
  end
end


class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = options[:class_name]   || name.capitalize.to_s
    @foreign_key = options[:foreign_key] || "#{name.to_s.singularize}_id".to_sym
    @primary_key = options[:primary_key] || "id".to_sym
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name]   || name.to_s.singularize.capitalize
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase}_id".to_sym
    @primary_key = options[:primary_key] || "id".to_sym
  end
end

module Associatable
  # Phase IIIb

  def assoc_options
    @assoc_options ||= {}
  end


  def belongs_to(name, options = {})
    opts = BelongsToOptions.new(name, options)
    assoc_options[name] = opts

    define_method(name) do
      f_key = self.send(opts.foreign_key) #returns a value, not a method name
      m_class = opts.model_class
      m_class.where({ opts.primary_key => f_key }).first
    end
  end


  def has_many(name, options = {})
    opts = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      p_key = self.send(opts.primary_key)
      m_class = opts.model_class
      m_class.where({ opts.foreign_key => p_key })
    end
  end
end


class SQLObject
  extend Associatable
end
