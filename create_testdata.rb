require './controllers/staff.rb'
require './controllers/student.rb'
require './controllers/onduty.rb'

test_passwd = 'jfiodsjfkdsFYufsdyf8hB'

# 管理者スタッフ
result = StaffController.create_admin({
  email: 'a@admin.ex',
  user_name: '管理者A',
  raw_passwd: test_passwd
})
puts "admin  :#{result.to_json}"

result = StaffController.create_admin({
  email: 'b@admin.ex',
  user_name: '管理者B',
  raw_passwd: test_passwd
})
puts "admin  :#{result.to_json}"

# 通常スタッフ
result = StaffController.create_normal({
  email: 'a@staff.ex',
  user_name: 'スタッフA',
  raw_passwd: test_passwd,
  config_passwd: test_passwd
})
puts "staff  :#{result.to_json}"

result = StaffController.create_normal({
  email: 'b@staff.ex',
  user_name: 'スタッフB',
  raw_passwd: test_passwd,
  config_passwd: test_passwd
})
puts "staff  :#{result.to_json}"

# 学生
# result = StudentController.create({
#   student_id: '21101',
#   user_name: '学生A',
#   grade: 1,
#   department_id: 1,
#   room_num: '1101',
#   raw_passwd: test_passwd,
#   config_passwd: test_passwd
# })
# puts "student:#{result.to_json}"

# result = StudentController.create({
#   student_id: '19201',
#   user_name: '学生B',
#   grade: 3,
#   department_id: 2,
#   room_num: '1201',
#   raw_passwd: test_passwd,
#   config_passwd: test_passwd
# })
# puts "student:#{result.to_json}"

# result = StudentController.create({
#   student_id: '17301',
#   user_name: '学生C',
#   grade: 5,
#   department_id: 3,
#   room_num: '2101',
#   raw_passwd: test_passwd,
#   config_passwd: test_passwd
# })
# puts "student:#{result.to_json}"

# 当直
result = OndutyController.create({
  staff_id: 1,
  time: {
    year: 2021,
    month: 12,
    date: 29
  }
})
puts "onduty :#{result.to_json}"

result = OndutyController.create({
  staff_id: 1,
  time: {
    year: 2021,
    month: 12,
    date: 30
  }
})
puts "onduty :#{result.to_json}"

result = OndutyController.create({
  staff_id: 2,
  time: {
    year: 2021,
    month: 12,
    date: 31
  }
})
puts "onduty :#{result.to_json}"
