require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    # through_opts is actually the assoc_options for the class of `self`.
    # ::assoc_options returns a hash with the key of class `self`.

    define_method(name) do
      through_opts = self.class.assoc_options[through_name]
      source_opts = through_opts.model_class.assoc_options[source_name]

      through_table = through_opts.table_name
      join_table = source_opts.class_name.tableize

      selectline = "SELECT #{through_table}.*"
      fromline = "FROM #{through_table}"
      joinline = "JOIN #{join_table}"
      online = "ON #{through_table}.#{source_opts.foreign_key} = #{join_table}.#{source_opts.primary_key}"
      whereline = "WHERE #{through_table}.#{through_opts.primary_key} = #{self.send(through_opts.foreign_key)}"

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
                 .find(through_object.send(source_opts.foreign_key))
    end

  end
end
