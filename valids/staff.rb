require './models/staff.rb'
require './valids/user.rb'
require './valids/helpers.rb'
require './helpers/error.rb'

class StaffValid
  class Fields
    # スタッフIDでのバリデーション
    def self.id(id)
      result = { is_ok: false }

      # スタッフIDと対応するスタッフがいない場合
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
    # スタッフを作成するときのバリデーション
    def self.create(info)
      result = { is_ok: false }
      data = {}

      # ユーザーを作成するときのバリデーション
      field_result = format_field_results([
        UserValid::Procs.create(info)
      ])
      # ユーザーを作成するときのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがすでにいた場合, エラーメッセージをスタッフ用に書き換える
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

    # スタッフを変更するときのバリデーション
    def self.update(id, info)
      result = { is_ok: false }

      # スタッフIDと対応するスタッフがいなかった場合はバリデーション失敗
      record = StaffModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: 'メールアドレスと対応するスタッフがいません')
        return result
      end

      # ユーザー変更時のバリデーション
      field_result = format_field_results([
        UserValid::Procs.update(record.user_id, info)
      ])
      # ユーザー変更時のバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    # スタッフのパスワードを変更するときのバリデーション
    def self.update_passwd(id, info)
      result = { is_ok: false }

      # ユーザーのパスワード編集でのバリデーション
      record = StaffModel.get_by_id(id)
      field_result = format_field_results([
        UserValid::Procs.update_passwd(record.user_id, info)
      ])
      # ユーザーのパスワード編集でのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがいなかった場合, エラーメッセージをスタッフ用に書き換える
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = 'メールアドレスと対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    # スタッフを削除するときのバリデーション
    def self.delete(id)
      result = { is_ok: false }

      # ユーザー削除のバリデーション
      record = StaffModel.get_by_id(id)
      field_result = format_field_results([
        UserValid::Procs.delete(record.user_id)
      ])
      # ユーザー削除のバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがいなかった場合, エラーメッセージをスタッフ用に書き換える
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = 'メールアドレスと対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      # 管理者のスタッフを削除しようとしていた場合はバリデーション失敗
      if record.is_admin
        result[:err] = err_obj(400, $err_types[:PROCESS_NOT_ALLOWED], msg: '管理者は削除できません')
        return result
      end

      result[:is_ok] = true
      result
    end

    # スタッフがログインするときのバリデーション
    def self.login(info)
      result = { is_ok: false }

      # ユーザーがログインするときのバリデーション
      field_result = format_field_results([
        UserValid::Procs.login(info),
      ])
      # ユーザーがログインするときのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがいなかった場合, エラーメッセージをスタッフ用に書き換える
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
