require './models/student.rb'
require './models/onduty.rb'
require './valids/onduty.rb'
require './valids/helpers.rb'
require './helpers/error.rb'

class RollcallValid
  class Fields
    # 学生でのバリデーション
    def self.student(student_id)
      result = { is_ok: false }

      record = StudentModel.get_by_id(student_id)
      # 学生がいない場合はバリデーション失敗
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: '学籍番号と対応する学生がいません')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 点呼時の学生の画像でのバリデーション
    def self.student_img(img)
      result = { is_ok: false }

      # 画像がない場合はバリデーション失敗
      if img.nil?
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '画像がありません')
        return result
      end

      result[:data] = {
        hashed_img_name: "#{SecureRandom.hex(16)}.#{img[:filename].split('.')[-1]}"
      }
      result[:is_ok] = true
      result
    end
  end
  class Procs
    # 学生の点呼を行うときのバリデーション
    def self.rollcall_by_student_today(info)
      result = { is_ok: false }

      # カラムごとのバリデーション
      field_result = format_field_results([
        RollcallValid::Fields.student(info[:student_id]),
        RollcallValid::Fields.student_img(info[:student_img])
      ])
      # カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      now = Time.now
      rollcall = RollcallModel.get_by_student_time(info[:student_id], {
        year: now.year, month: now.month, date: now.day
      })
      # すでに点呼している場合はバリデーション失敗
      if rollcall.is_student_done
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_NECESSARY], msg: 'すでに点呼しています')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 当直の点呼確認をするときのバリデーション
    def self.check_by_onduty(info)
      result = { is_ok: false }

      # カラムごとのバリデーション
      field_result = format_field_results([
        RollcallValid::Fields.student(info[:student_id]),
        OndutyValid::Fields.time(info[:time])
      ])
      # カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end

      rollcall = RollcallModel.get_by_student_time(info[:student_id], info[:time])
      # まだ学生が点呼をしていないときはバリデーション失敗
      unless rollcall.is_student_done
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_ALLOWED], msg: 'まだ学生が点呼していません')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 点呼確認を強制的に行うときのバリデーション
    def self.forcedcheck_by_onduty(info)
      result = { is_ok: false }

      # カラムごとのバリデーション
      field_result = format_field_results([
        RollcallValid::Fields.student(info[:student_id]),
        OndutyValid::Fields.time(info[:time])
      ])
      # カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end

      result[:is_ok] = true
      result
    end

    # 点呼をやり直すときのバリデーション
    def self.startover_by_onduty(info)
      result = { is_ok: false }

      # カラムごとのバリデーション
      field_result = format_field_results([
        RollcallValid::Fields.student(info[:student_id]),
        OndutyValid::Fields.time(info[:time])
      ])
      # カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end

      rollcall = RollcallModel.get_by_student_time(info[:student_id], info[:time])
      # 学生がまだ点呼を行っていない場合はバリデーション失敗
      unless rollcall.is_student_done
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_ALLOWED], msg: 'まだ学生が点呼していません')
        return result
      end

      result[:is_ok] = true
      result
    end
  end
end
