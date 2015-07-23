require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # how can self.table_name be parameterized? is this a risk?
    return @db_cols if @db_cols

    @db_cols ||= DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{self.table_name}
      LIMIT 0
    SQL

    @db_cols.flatten!.map!(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column_name|
      define_method("#{column_name}") { attributes[column_name] }
      define_method("#{column_name}=") { |val| attributes[column_name] = val }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || "#{self}".tableize # still messes up 'human' though
  end

  def self.all
    raw_db_results = DBConnection.execute(<<-SQL)
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
    SQL

    self.parse_all(raw_db_results)
  end

  def self.parse_all(results)
    # map, not each - we want the new array here
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{self.table_name}
      WHERE id = ?
      LIMIT 1
    SQL

    # ::parse_all will return either empty array, or 1-size array with this id
    # [].first => nil, anything_else.first => the found object
    self.parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, attr_val|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end

      self.send("#{attr_name}=", attr_val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns.join(', ')[4..-1] #gets rid of 'id, '
    question_marks = (['?'] * (self.class.columns.size - 1)).join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    setline = self.class.columns.map do |col_name|
      "#{col_name} = ?" unless col_name == :id
    end.compact!

    setattrs = attribute_values.drop(1)

    DBConnection.execute(<<-SQL, *setattrs)
      UPDATE
        #{self.class.table_name}
      SET
        #{setline.join(', ')}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
