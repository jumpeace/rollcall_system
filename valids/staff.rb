require './models/staff.rb'
require './valids/user.rb'
require './valids/helpers.rb'
require './helpers/error.rb'

class StaffValid
  class Fields
    def self.id(id)
      result = { is_ok: false }

      record = StaffModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: 'メールアドレスと対応するスタッフがいません')
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

      field_result = exec_field_procs([
        UserValid::Procs.create(info)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:DUPLICATE_NOT_ALLOWED] && !result[:err][:details].nil?
          result[:err][:msg] = 'メールアドレスと対応するスタッフがすでにいます' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      data = data.merge(field_result[:data])

      result[:data] = data
      result[:is_ok] = true
      result
    end

    def self.update(id, info)
      result = { is_ok: false }

      record = StaffModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: 'メールアドレスと対応するスタッフがいません')
        return result
      end

      field_result = exec_field_procs([
        UserValid::Procs.update(record.user_id, info)
        # StaffValid::Fields.is_teacher(info[:is_teacher], false)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    def self.update_passwd(id, info)
      result = { is_ok: false }

      record = StaffModel.get_by_id(id)
      field_result = exec_field_procs([
        UserValid::Procs.update_passwd(record.user_id, info)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = 'メールアドレスと対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    def self.delete(id)
      result = { is_ok: false }

      record = StaffModel.get_by_id(id)
      field_result = exec_field_procs([
        UserValid::Procs.delete(record.user_id)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = 'メールアドレスと対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      if record.is_admin
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_ALLOWED], msg: '管理者は削除できません')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.login(info)
      result = { is_ok: false }

      field_result = exec_field_procs([
        UserValid::Procs.login(info),
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = 'メールアドレスと対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end
  end
end
