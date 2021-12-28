require './controllers/onduty.rb'
require './controllers/rollcall.rb'

def exec_tasks
  is_same_minute = false
  pre_time = nil

  rollcall_prepare_time = RollcallController.rollcalling_time[:prepare]
  create_onday_time = OndutyController.creating_onday_time

  loop do
    is_task_done = false
    results = []

    now = Time.now

    is_same_minute = now.hour == pre_time[:hour] && now.min == pre_time[:minute] unless pre_time.nil?
    # 1分ごとの命令
    unless is_same_minute
      # 0時で当日の点呼のレコードがなかったらランダム管理者（なかったらスタッフ）で追加する
      if now.hour == create_onday_time[:hour] && now.min == create_onday_time[:minute]
        results.push(OndutyController.create_onday)
        is_task_done = true
      end
      # 点呼の時間に自動的に新しいレコードを追加する
      if now.hour == rollcall_prepare_time[:hour] && now.min == rollcall_prepare_time[:minute]
        results.push(RollcallController.creates_by_onday_onduty)
        is_task_done = true
      end
    end

    if is_task_done
      puts "[#{now}]"
      results.each do |result|
        puts "　#{result[:msg]}"
      end
    end

    # 実行した時間を記録しておく
    pre_time = { hour: now.hour, minute: now.min }

    sleep(5)
  end
end
