require 'active_record'

ActiveRecord::Base.configurations = YAML.load_file('db.yml')
ActiveRecord::Base.establish_connection :development