require_relative 'utilities'

module Ferry
  class Importer < Utilities
    def row_sql_format(hash, columns, adapter)
      values = hash.values_at(*columns)
      values.map! do |value|
        if(adapter=="mysql2" && (value=='t' || value =='f'))
          value=='t' ? value=1 : value=0  #attempt to convert 't' and 'f' to int in mysql
        end
        value = ActiveRecord::Base::sanitize(value)
      end
      "(#{values.join(",")})"
    end

    def insert_sql(model, columns, values)
      col_names_sql = "(#{columns.join(",")})"
      model_sql = model.downcase
      sql_insert_beg = "INSERT INTO #{model_sql} #{col_names_sql} VALUES "
      ActiveRecord::Base.connection.begin_db_transaction
        values.each_slice(1000) do |records|
          sql_statement = sql_insert_beg + records.join(",") + ";"
          ActiveRecord::Base.connection.execute(sql_statement)
        end
      ActiveRecord::Base.connection.commit_db_transaction
    end

    def import(environment, model, filename)
      db_connect(environment)
      adapter = YAML::load(IO.read("config/database.yml"))[environment]["adapter"]
      if(File.extname(filename) != ".csv")
        puts "Import aborted -- only csv import is supported"
        return false
      end
      lines = CSV.read(filename)#encoding option here? might break given db's limits
      if(lines.nil?)
        puts "Import aborted -- file not found"
        return false
      end
      import_bar = ProgressBar.new("import", lines.length-1)
      col_names = lines.shift
      records = []
      lines.each do |line|
        record = Hash[col_names.zip line]
        records << record
      end
      values = []
      records.map do |record|
        values << row_sql_format(record, col_names, adapter)
        import_bar.inc
      end
      insert_sql(model, col_names, values)
      puts ""
      puts "csv imported to #{model} table"
    end
  end
end
