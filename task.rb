require './controllers/onduty.rb'
require './controllers/rollcall.rb'

def exec_tasks
  # 前回のループと同じ分かを格納
  is_same_minute = false
  # 前回のループの時間を保持
  pre_time = nil

  # 当日の当直を自動追加する時間
  create_onday_time = OndutyController.creating_onday_time
  # 当日の点呼表を自動追加する時間
  rollcall_prepare_time = RollcallController.rollcalling_time[:prepare]

  loop do
    is_task_done = false
    results = []

    now = Time.now

    # 1分ごとに命令を実行する
    is_same_minute = now.hour == pre_time[:hour] && now.min == pre_time[:minute] unless pre_time.nil?
    unless is_same_minute
      # 当日の当直の自動追加
      if now.hour == create_onday_time[:hour] && now.min == create_onday_time[:minute]
        results.push(OndutyController.create_onday)
        is_task_done = true
      end
      # 当日の点呼表の自動追加
      if now.hour == rollcall_prepare_time[:hour] && now.min == rollcall_prepare_time[:minute]
        results.push(RollcallController.creates_by_onday_onduty)
        is_task_done = true
      end
    end

    # 何らかの処理が実行されたら実行結果を表示する
    if is_task_done
      puts "[#{now}]"
      results.each do |result|
        puts "　#{result[:msg]}"
      end
    end

    # 1分ごとに実行するために実行した時間を記録しておく
    pre_time = { hour: now.hour, minute: now.min }

    # ループの間隔は5秒
    sleep(5)
  end
end
