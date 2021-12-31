require 'active_record'

# アクティブレコードを使用するための設定
ActiveRecord::Base.configurations = YAML.load_file('db.yml')
ActiveRecord::Base.establish_connection :development