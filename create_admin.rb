require './controllers/staff.rb'

if ARGV.size == 3
  # 管理者スタッフを作成
  result = create_admin_staff({
    email: ARGV[0],
    user_name: ARGV[1],
    raw_passwd: ARGV[2]
  })
  # 管理者スタッフの作成結果を表示
  puts result
end

