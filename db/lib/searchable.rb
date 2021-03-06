module Searchable
  def where(params)
    whereline = params.map { |key, _| "#{key} = ?" }

    results = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{whereline.join(" AND ")}
    SQL

    results.map { |result| self.new(result) }
  end
end
