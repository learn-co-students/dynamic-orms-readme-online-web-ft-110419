require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize
  end

  #The self.table_name method, which you'll see in the Song class in lib/song.rb,
  #takes the name of the class, referenced by the self keyword,
  #turns it into a string with #to_s, downcases (or "un-capitalizes") that string
  #and then "pluralizes" it, or makes it plural.

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  #Here we write a SQL statement using the pragma keyword and the 
  #table_name method (to access the name of the table we are querying). 
  #We iterate over the resulting array of hashes to collect just the name of each column. 
  #We call #compact on that just to be safe and get rid of any nil values that may end up in our collection.
  #Now that we have a method that returns us an array of column names, 
  #we can use this collection to create the attr_accessors of our Song class.

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  #Here, we iterate over the column names stored in the column_names class method
  #and set an attr_accessor for each one, making sure to convert the column name string
  #into a symbol with the #to_sym method, since attr_accessors must be named with symbols.

  #This is metaprogramming because we are writing code that writes code for us. 
  #By setting the attr_accessors in this way, a reader and writer method for each column name
  #is dynamically created, without us ever having to explicitly name each of these methods.

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
  #we want our #initialize method to be abstract, i.e. not specific to the Song class
  
  #Here, we define our method to take in an argument of options, which defaults to an empty hash. 
  #We expect #new to be called with a hash, so when we refer to options inside the #initialize method, 
  #we expect to be operating on a hash.

  #We iterate over the options hash and use our fancy metaprogramming #send method to interpolate
  #the name of each hash key as a method that we set equal to that key's value. 
  #As long as each property has a corresponding attr_accessor, this #initialize method will work.

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  #Using String interpolation for a SQL query creates a SQL injection vulnerability, 
  #which we've previously stated is a bad idea as it creates a security issue, 
  #however, we're using these examples to illustrate how dynamic ORMs work.

  #Recall, however, that the conventional #save is an instance method. 
  #So, inside a #save method, self will refer to the instance of the class, 
  #not the class itself. In order to use a class method inside an instance method, 
  #we need to do the following:

  def table_name_for_insert
    self.class.table_name
  end

  #self will refer to the instance of the class itself.
  #class will refer to the class, then we invoke the table_name method onto the class.

  #Let's iterate over the column names stored in #column_names and 
  #use the #send method with each individual column name to invoke the method 
  #by that same name and capture the return value:

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  #There's one problem though. When we INSERT a row into a database table for the first time, 
  #we don't INSERT the id attribute. In fact, our Ruby object has an id of nil before it is inserted into the table. 
  #The magic of our SQL database handles the creation of an ID for a given table row and 
  #then we will use that ID to assign a value to the original object's id attribute.

  #We do this with the col_names_for_insert method.
  #Our column names returned by the col_names_for_insert method originally were set into an array.
  #Let's turn them into a comma separated list, contained in a string using the join method:

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  #The method above deletes the id column from the column names. We want the database to create
  #the unique Id for the rows. We don't want to create the id here.

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  #This method is dynamic and abstract because it does not reference the table name explicitly. 
  #Instead it uses the #table_name class method we built that will return the table name associated with any given class.

end



