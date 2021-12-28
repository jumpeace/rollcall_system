require './models/onduty.rb'
require './valids/helpers.rb'
require './helpers/error.rb'
require './helpers/time.rb'

class OndutyValid
  class Fields
    def self.staff_id(staff_id)
      result = { is_ok: false }

      get_result = get_staff(staff_id)
      if get_result.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: 'スタッフが存在しません')
        return result
      end

      result
    end

    def self.time(time)
      result = { is_ok: false }

      unless MyTime.correct_time?(time[:year].to_i, time[:month].to_i, date: time[:date].to_i)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '時間が正しくありません')
        return result
      end

      result[:is_ok] = true
      result
    end
  end

  class Procs
    def self.create(info)
      result = { is_ok: false }
      data = {}

      unless OndutyModel.get_by_time(info[:time]).nil?
        result[:err] = err_obj(400, $err_types[:DUPLICATE_NOT_ALLOWED], msg: '対応する日時の当直はすでにいます', details: { model: 'onduty' })
        return result
      end

      field_result = exec_field_procs([
        OndutyValid::Fields.time(info[:time]),
        StaffValid::Fields.id(info[:staff_id])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      result[:data] = data
      result[:is_ok] = true
      result
    end

    def self.update(time, info)
      result = { is_ok: false }
      data = {}

      record = OndutyModel.get_by_time(time)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: '対応する日時の当直が存在しません', details: { model: 'onduty' })
        return result
      end
      data[:id] = record.id

      field_result = exec_field_procs([
        StaffValid::Fields.id(info[:staff_id])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      result[:data] = data
      result[:is_ok] = true
      result
    end
  end
end
