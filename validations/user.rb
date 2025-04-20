require './models/user.rb'
require './validations/helpers.rb'
require './helpers/error.rb'

class UserValid
  class Fields
    # メールアドレスでのバリデーション
    def self.email(email)
      result = { is_ok: false }

      # メールアドレスが入力されていない場合はバリデーション失敗
      if email.nil? || email == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'メールアドレスは必須です')
        return result
      end

      # メールアドレスが256文字以下でない場合はバリデーション失敗
      unless email.match(/^.{1,256}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'メールアドレスは256文字以下にしてください')
        return result
      end

      # メールアドレスのフォーマットが正しくない場合はバリデーション失敗
      unless email.match(/^[a-zA-Z0-9_.+-]+@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg:  'メールアドレスのフォーマットが間違っています')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 名前でのバリデーション
    def self.name(user_name)
      result = { is_ok: false }

      # 名前が入力されていない場合はバリデーション失敗
      if user_name.nil? || user_name == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'ユーザー名は必須です')
        return result
      end

      # 名前が90文字以下でない場合はバリデーション失敗
      unless user_name.match(/^.{1,90}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'ユーザー名は90文字以下にしてください')
        return result
      end

      # 名前に記号が含まれる場合はバリデーション失敗
      if user_name.match(/[!"#\$%&'\(\)=\-~\^\|_`@\[\{;\+:\*\]\},<\.>\/\?\\]/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'ユーザー名に記号は使えません')
        return result
      end

      result[:is_ok] = true
      result
    end

    # パスワードでのバリデーション
    def self.passwd(raw_passwd, config_passwd)
      result = { 'is_ok': false }

      # パスワードが入力されていない場合はバリデーション失敗
      if raw_passwd.nil? || raw_passwd == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'パスワードは必須です')
        return result
      end

      # 確認用パスワードが入力されていない場合はバリデーション失敗
      if config_passwd.nil? || config_passwd == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '確認用パスワードは必須です')
        return result
      end

      # パスワードが20文字以上50文字以下でない場合はバリデーション失敗
      unless raw_passwd.match(/^.{20,50}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードは20文字以上50文字以下にしてください')
        return result
      end

      # パスワードのアルファベットの小文字が含まれていない場合はバリデーション失敗
      unless raw_passwd.match(/(?=.*[a-z]).+/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードにアルファベット小文字を1文字以上含んでください')
        return result
      end

      # パスワードのアルファベットの大文字が含まれていない場合はバリデーション失敗
      unless raw_passwd.match(/(?=.*[A-Z]).+/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードにアルファベット大文字を1文字以上含んでください')
        return result
      end

      # パスワードの数字が含まれていない場合はバリデーション失敗
      unless raw_passwd.match(/(?=.*\d).+/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードに数字を1文字以上含んでください')
        return result
      end

      # パスワードに記号が含まれている場合はバリデーション失敗
      if raw_passwd.match(/[!"#\$%&'\(\)=\-~\^\|_`@\[\{;\+:\*\]\},<\.>\/\?\\]/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードに記号は使えません')
        return result
      end

      # パスワードと確認用パスワードが一致しない場合はバリデーション失敗
      if raw_passwd != config_passwd
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードと確認用のパスワードが一致しません')
        return result
      end

      result[:is_ok] = true
      result
    end
  end

  class Procs
    # ユーザーを作成するときのバリデーション
    def self.create(info)
      result = { is_ok: false }
      data = {}

      # メールアドレスでのバリデーション
      field_result = format_field_results([
        UserValid::Fields.email(info[:email])
      ])
      # メールアドレスでのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      # すでにメールアドレスと対応するユーザーがいた場合はバリデーション失敗
      unless UserModel.get_by_email(info[:email]).nil?
        result[:err] = err_obj(400, $err_types[:DUPLICATE_NOT_ALLOWED], details: { model: 'user' })
        return result
      end

      # カラムごとのバリデーション
      field_result = format_field_results([
        UserValid::Fields.name(info[:user_name]),
        UserValid::Fields.passwd(info[:raw_passwd], info[:config_passwd])
      ])
      # カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      result[:data] = data
      result[:is_ok] = true
      result
    end

    # ユーザーを編集するときのバリデーション
    def self.update(id, info)
      result = { is_ok: false }

      # ユーザーIDと対応するユーザーがいなかった場合はバリデーション失敗
      if UserModel.get_by_id(id).nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      # 名前でのバリデーション
      field_result = format_field_results([
        UserValid::Fields.name(info[:user_name])
      ])
      # 名前のバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    # ユーザーのパスワードを変更するときのバリデーション
    def self.update_passwd(id, info)
      result = { is_ok: false }

      # ユーザーIDと対応するユーザーがいなかった場合はバリデーション失敗
      record = UserModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      # 現在のパスワードが異なる場合はバリデーション失敗
      unless passwd_correct?(info[:now_passwd], record.passwd, record.salt)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '現在のパスワードが違います')
        return result
      end
      
      # 新しいパスワードでのバリデーション
      field_result = UserValid::Fields.passwd(info[:new_passwd], info[:new_passwd])
      # 新しいパスワードでのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data].nil? ? {} : field_result[:data]
      result[:data][:salt] = record.salt

      result[:is_ok] = true
      result
    end

    # ユーザーを削除するときのバリデーション
    def self.delete(id)
      result = { is_ok: false }
      # ユーザーIDと対応するユーザーが存在しないときはバリデーション失敗
      if UserModel.get_by_id(id).nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      result[:is_ok] = true
      result
    end

    # ユーザーがログインするときのバリデーション
    def self.login(info)
      result = { is_ok: false }

      # メールアドレスが入力されていない場合はバリデーション失敗
      if info[:email].nil? || info[:email] == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'メールアドレスは必須です')
        return result
      end

      # パスワードが入力されていない場合はバリデーション失敗
      if info[:passwd].nil? || info[:passwd] == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'パスワードは必須です')
        return result
      end

      record = UserModel.get_by_email(info[:email])
      # メールアドレスと対応するユーザーがいなかった場合はバリデーション失敗
      if record.nil?
        result[:err] = err_obj(400, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      # パスワードが正しくなかった場合はバリデーション失敗
      unless passwd_correct?(info[:passwd], record.passwd, record.salt)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードが違います')
        return result
      end

      result[:data] = {
        user_id: record.id
      }
      result[:is_ok] = true
      result
    end
  end
end
