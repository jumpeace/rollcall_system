require './models/student.rb'
require './models/onduty.rb'
require './valids/onduty.rb'
require './valids/helpers.rb'
require './helpers/error.rb'

class RollcallValid
  class Fields
    def self.student(student_id)
      result = { is_ok: false }

      record = StudentModel.get_by_id(student_id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: '学籍番号と対応する学生がいません')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.student_img(img)
      result = { is_ok: false }

      if img.nil?
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '画像がありません')
        return result
      end

      result[:data] = {
        hashed_img_name: "#{SecureRandom.hex(16)}.#{img[:filename].split('.')[-1]}"
      }
      p result[:data]
      result[:is_ok] = true
      result
    end
  end
  class Procs
    def self.update_student_done_today(info)
      result = { is_ok: false }

      field_result = exec_field_procs([
        RollcallValid::Fields.student(info[:student_id]),
        RollcallValid::Fields.student_img(info[:student_img])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      now = Time.now
      rollcall = RollcallModel.get_by_student_time(info[:student_id], {
        year: now.year, month: now.month, date: now.day
      })
      if rollcall.is_student_done
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_NECESSARY], msg: 'すでに点呼しています')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.check_by_onduty(info)
      result = { is_ok: false }

      field_result = exec_field_procs([
        RollcallValid::Fields.student(info[:student_id]),
        OndutyValid::Fields.time(info[:time])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end

      rollcall = RollcallModel.get_by_student_time(info[:student_id], info[:time])
      unless rollcall.is_student_done
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_ALLOWED], msg: 'まだ学生が点呼していません')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.forcedcheck_by_onduty(info)
      result = { is_ok: false }

      field_result = exec_field_procs([
        RollcallValid::Fields.student(info[:student_id]),
        OndutyValid::Fields.time(info[:time])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.startover_by_onduty(info)
      result = { is_ok: false }

      field_result = exec_field_procs([
        RollcallValid::Fields.student(info[:student_id]),
        OndutyValid::Fields.time(info[:time])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end

      rollcall = RollcallModel.get_by_student_time(info[:student_id], info[:time])
      unless rollcall.is_student_done
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_ALLOWED], msg: 'まだ学生が点呼していません')
        return result
      end

      result[:is_ok] = true
      result
    end
  end
end
