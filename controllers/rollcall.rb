require './models/rollcall.rb'
require './models/onduty.rb'
require './validations/rollcall.rb'
require './helpers/time.rb'

class RollcallController
  # 点呼の準備時間, 点呼開始時間, 点呼終了時間を取得
  def self.rollcalling_time
    {
      prepare: { hour: Time.now.hour, minute: Time.now.min },
      # start: { hour: 0, minute: 0 },
      # prepare: { hour: 21, minute: 29 },
      start: { hour: 21, minute: 30 },
      # due: { hour: 23, minute: 59 }
      due: { hour: 22, minute: 0 }
    }
  end

  # 点呼の時間になったら自動的に追加
  def self.creates_by_onday_onduty
    result = { is_ok: false }

    now = Time.now
    rollcalls = RollcallModel.gets_by_time({ year: now.year, month: now.month, date: now.day })[:rollcalls]
    # 当日の点呼表がすでに追加されている場合は処理を行わない
    rollcalls.length
    if rollcalls.length.positive?
      result[:msg] = '今日の分の点呼表はすでに追加されています'
      return result
    end

    # 当日の点呼表を追加する
    onduty = OndutyModel.get_today
    RollcallModel.creates_by_onduty({ onduty_id: onduty.id })

    result[:is_ok] = true
    result[:msg] = '今日の分の点呼表を追加しました'
    result
  end

  # 点呼時間内であるかを判定して点呼できるかどうかを判定する
  def self.able_rollcall?
    rollcall_time = RollcallController.rollcalling_time
    return false if MyTime.compare_time(rollcall_time[:start][:hour], rollcall_time[:start][:minute]) == 'future'
    return false if MyTime.compare_time(rollcall_time[:due][:hour], rollcall_time[:due][:minute]) == 'past'

    true
  end

  # 当日の学籍番号と対応する学生の点呼を行う
  def self.rollcall_today_by_student(student_id, info)
    result = { is_ok: false }

    # バリデーション
    valid_result = RollcallValid::Procs.rollcall_by_student_today({ student_id: student_id, student_img: info[:student_img] })
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    hashed_img_name = valid_result[:data][:hashed_img_name]

    # 点呼時の学生の画像を保存
    File.open("./public/files/rollcall/#{hashed_img_name}", 'wb') do |save_fp|
      upload_fp = info[:student_img][:tempfile]
      write_data = upload_fp.read
      save_fp.write write_data
    end

    # 学籍番号と対応する学生を点呼済にする
    RollcallModel.rollcall_today_by_student(student_id, { student_img_name: hashed_img_name })

    result[:is_ok] = true
    result
  end

  # 特定の日にちの学籍番号と対応する学生の点呼確認を行う
  def self.check_by_onduty(student_id, time)
    result = { is_ok: false }

    # バリデーション
    valid_result = RollcallValid::Procs.check_by_onduty({ student_id: student_id, time: time })
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # 学籍番号と対応する学生を点呼確認済にする
    RollcallModel.check_by_onduty(student_id, time)

    result[:is_ok] = true
    result
  end

  # 特定の日にちの複数の学生の点呼確認を行う
  def self.checks_by_onduty(student_ids, time)
    result = { is_ok: false }
    not_found_ids = []
    not_allowed_ids = []
    not_necessary_ids = []

    # 学生ごとに処理を行う
    student_ids.each do |student_id|
      check_result = RollcallController.check_by_onduty(student_id, time)
      unless check_result[:is_ok]
        not_found_ids.push(student_id) if check_result[:err][:type] == $err_types[:NOT_FOUND]
        not_necessary_ids.push(student_id) if check_result[:err][:type] == $err_types[:PROCESS_NOT_NECESSARY]
        not_allowed_ids.push(student_id) if check_result[:err][:type] == $err_types[:PROCESS_NOT_ALLOWED]
      end
    end

    result[:errs] = []
    # 一人以上の学生が見つからなくて点呼確認ができなかった場合
    unless not_found_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "学籍番号#{not_found_ids.join(',')}の学生は存在しないため確認ができませんでした"))
      return result
    end
    # 一人以上の学生が点呼していなくて点呼確認ができなかった場合
    unless not_allowed_ids.length.zero?
      result[:errs].push(err_obj(400, $err_types[:PROCESS_NOT_ALLOWED],
        msg: "学籍番号#{not_allowed_ids.join(',')}の学生はまだ点呼していません"))
      return result
    end

    result[:is_ok] = true
    result
  end

  # 特定の日にちの学籍番号と対応する学生の点呼確認を強制的に行う
  def self.forcedcheck_by_onduty(student_id, time)
    result = { is_ok: false }

    # バリデーション
    valid_result = RollcallValid::Procs.forcedcheck_by_onduty({ student_id: student_id, time: time })
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # 学籍番号と対応する学生を強制的に点呼確認済にする
    RollcallModel.forcedcheck_by_onduty(student_id, time)

    result[:is_ok] = true
    result
  end

  # 特定の日にちの複数の学生の点呼確認を強制的に行う
  def self.forcedchecks_by_onduty(student_ids, time)
    result = { is_ok: false }
    not_found_ids = []
    not_necessary_ids = []

    # 学生ごとに処理を行う
    student_ids.each do |student_id|
      check_result = RollcallController.forcedcheck_by_onduty(student_id, time)
      unless check_result[:is_ok]
        not_found_ids.push(student_id) if check_result[:err][:type] == $err_types[:NOT_FOUND]
        not_necessary_ids.push(student_id) if check_result[:err][:type] == $err_types[:PROCESS_NOT_NECESSARY]
        not_allowed_ids.push(student_id) if check_result[:err][:type] == $err_types[:PROCESS_NOT_ALLOWED]
      end
    end

    result[:errs] = []
    # 一人以上の学生が見つからなくて点呼確認ができなかった場合
    unless not_found_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "学籍番号#{not_found_ids.join(',')}の学生は存在しないため確認ができませんでした"))
      return result
    end

    result[:is_ok] = true
    result
  end

  # 特定の日にちの学籍番号と対応する学生の点呼をやり直す
  def self.startover_by_onduty(student_id, time)
    result = { is_ok: false }

    # バリデーション
    valid_result = RollcallValid::Procs.startover_by_onduty({ student_id: student_id, time: time })
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # 学籍番号と対応する学生の点呼をやり直す
    RollcallModel.startover_by_onduty(student_id, time)

    result[:is_ok] = true
    result
  end

  # 特定の日にちの複数の学生の点呼をやり直す
  def self.startovers_by_onduty(student_ids, time)
    result = { is_ok: false }
    not_found_ids = []
    not_allowed_ids = []
    not_necessary_ids = []

    # 学生ごとに処理を行う
    student_ids.each do |student_id|
      check_result = RollcallController.startover_by_onduty(student_id, time)
      unless check_result[:is_ok]
        not_found_ids.push(student_id) if check_result[:err][:type] == $err_types[:NOT_FOUND]
        not_necessary_ids.push(student_id) if check_result[:err][:type] == $err_types[:PROCESS_NOT_NECESSARY]
        not_allowed_ids.push(student_id) if check_result[:err][:type] == $err_types[:PROCESS_NOT_ALLOWED]
      end
    end

    result[:errs] = []
    # 一人以上の学生が見つからなくて点呼のやり直しができなかった場合
    unless not_found_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "学籍番号#{not_found_ids.join(',')}の学生は存在しないため確認ができませんでした"))
      return result
    end
    # 一人以上の学生が点呼していなくて点呼のやり直しができなかった場合
    unless not_allowed_ids.length.zero?
      result[:errs].push(err_obj(400, $err_types[:PROCESS_NOT_ALLOWED],
        msg: "学籍番号#{not_allowed_ids.join(',')}の学生はまだ点呼していません"))
      return result
    end

    result[:is_ok] = true
    result
  end

  # 学籍番号と対応する学生の点呼が行われているかを判定
  def self.rollcall_today_student_done?(student_id)
    now = Time.now
    rollcall = RollcallModel.get_by_student_time(student_id, { year: now.year, month: now.month, date: now.day })
    rollcall.is_student_done
  end

  # 学籍番号と対応する学生の点呼確認が行われているかを判定
  def self.rollcall_today_onduty_done?(student_id)
    now = Time.now
    rollcall = RollcallModel.get_by_student_time(student_id, { year: now.year, month: now.month, date: now.day })
    rollcall.is_onduty_done
  end
end
