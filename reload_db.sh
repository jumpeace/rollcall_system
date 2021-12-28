rm db/main.db
sqlite3 db/main.db < db/init.sql
bundle exec ruby create_testdata.rb