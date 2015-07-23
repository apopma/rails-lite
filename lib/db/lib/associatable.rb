module Associatable

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

  def has_one_through(name, through_name, source_name)
    # through_opts is actually the assoc_options for the class of `self`.
    # ::assoc_options returns a hash with the key of class `self`.

    define_method(name) do
      through_opts = self.class.assoc_options[through_name]
      source_opts = through_opts.model_class.assoc_options[source_name]

      through_table = through_opts.table_name
      thru_pkey = through_opts.primary_key
      thru_fkey = through_opts.foreign_key

      join_table = source_opts.class_name.tableize
      src_pkey = source_opts.primary_key
      src_fkey = source_opts.foreign_key

      selectline = "SELECT #{through_table}.*"
      fromline = "FROM #{through_table}"
      joinline = "JOIN #{join_table}"
      online = "ON #{through_table}.#{src_fkey} = #{join_table}.#{src_pkey}"
      whereline = "WHERE #{through_table}.#{thru_pkey} = #{self.send(thru_fkey)}"

      results = DBConnection.execute(<<-SQL)
        #{selectline}
        #{fromline}
        #{joinline} #{online}
        #{whereline}
      SQL

      # Above SQL query doesn't actually return the source object, but instead,
      #    a 'through object' having the necessary foreign key to refer to it.
      #    Calling #send on this object to pull out the key value, along with
      #    SQLObject#find on this value, gives us our source object.

      through_object = through_opts.class_name.constantize
                                   .parse_all(results).first

      source_opts.class_name.constantize
                 .find(through_object.send(src_fkey))
    end
  end
end

# ------------------------------------------------------------

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
