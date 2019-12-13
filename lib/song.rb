require_relative "../config/environment.rb"
#require 'active_support/inflector'

class Song

  def self.table_name
    self.to_s.downcase + "s"
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = table_info.map {|row| row["name"]}
    column_names.compact
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end


  def initialize(hash)
    self.class.column_names.each do |column_name|
      if hash[column_name.to_sym]
        self.send("#{column_name}=", hash[column_name.to_sym])
      end
    end
  end 

  # def initialize(options={})
  #   options.each do |property, value|
  #     self.send("#{property}=", value)
  #   end
  # end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{self.send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  # def self.find_by_name(name)
  #   sql = "SELECT * FROM ? WHERE name = ?"
  #   DB[:conn].execute(sql, self.table_name, name)
  # end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



