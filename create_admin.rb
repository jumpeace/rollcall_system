require './controllers/staff.rb'

if ARGV.size == 3
  result = create_admin_staff({
    email: ARGV[0],
    user_name: ARGV[1],
    raw_passwd: ARGV[2]
  })
  puts result
end

