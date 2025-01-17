module Ferry
  class Utilities
    def db_connect(environment)
      db_config = YAML::load(IO.read("config/database.yml"))
      db_type = db_config[environment]["adapter"]

      if ['sqlite3', 'postgresql', 'mysql2'].include?(db_type)
        ActiveRecord::Base.establish_connection(adapter: db_type, database: db_config[environment]['database'])
        puts "operating with "+db_type
        return db_type
      else
        puts "Unsupported db type or no database associated with this application."
        return false
      end
    end

    def continue?(prompt = "Are you sure", default = false)
      a = ''
      s = default ? '[Y/n]' : '[y/N]'
      d = default ? 'y' : 'n'
      until %w[y n].include? a
        a = ask("#{prompt} #{s} ") { |q| q.limit = 1; q.case = :downcase }
        a = d if a.length == 0
      end
      a == 'y'
    end

    def init
      if !File.exist?("lib/tasks/ferry.rake")
        File.open("lib/tasks/ferry.rake", 'w') {|f| f.write("# this is your ferry init file
# in this file you can write rake tasks that are easily tailored to more case-by-case user implementations

namespace :ferry do
  # your code here!
end")}
        puts "/lib/tasks/ferry.rake created!"
      else
        puts "/lib/tasks/ferry.rake already exists - but you knew that already ... didn't you?"
      end
    end
  end
end
