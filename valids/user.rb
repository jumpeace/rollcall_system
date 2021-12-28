require './models/user.rb'
require './valids/helpers.rb'
require './helpers/error.rb'

class UserValid
  class Fields
    def self.email(email)
      result = { is_ok: false }

      if email.nil? || email == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'メールアドレスは必須です')
        return result
      end

      unless email.match(/^.{1,256}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'メールアドレスは256文字以下にしてください')
        return result
      end

      unless email.match(/^[a-zA-Z0-9_.+-]+@([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.)+[a-zA-Z]{2,}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg:  'メールアドレスのフォーマットが間違っています')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.name(user_name)
      result = { is_ok: false }

      if user_name.nil? || user_name == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'ユーザー名は必須です')
        return result
      end

      unless user_name.match(/^.{1,90}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'ユーザー名は90文字以下にしてください')
        return result
      end

      if user_name.match(/[!"#\$%&'\(\)=\-~\^\|_`@\[\{;\+:\*\]\},<\.>\/\?\\]/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'ユーザー名に記号や全角は使えません')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.passwd(raw_passwd, config_passwd)
      result = { 'is_ok': false }

      if raw_passwd.nil? || raw_passwd == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'パスワードは必須です')
        return result
      end

      if config_passwd.nil? || config_passwd == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '確認用パスワードは必須です')
        return result
      end

      unless raw_passwd.match(/^.{20,50}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードは20文字以上50文字以下にしてください')
        return result
      end

      # TODO 肯定先読みする必要ある？
      unless raw_passwd.match(/(?=.*[a-z]).+/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードにアルファベット小文字を1文字以上含んでください')
        return result
      end

      unless raw_passwd.match(/(?=.*[A-Z]).+/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードにアルファベット大文字を1文字以上含んでください')
        return result
      end

      unless raw_passwd.match(/(?=.*\d).+/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードに数字を1文字以上含んでください')
        return result
      end

      if raw_passwd.match(/[!"#\$%&'\(\)=\-~\^\|_`@\[\{;\+:\*\]\},<\.>\/\?\\]/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードに記号は使えません')
        return result
      end

      if raw_passwd != config_passwd
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: 'パスワードと確認用のパスワードが一致しません')
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
        UserValid::Fields.email(info[:email])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      unless UserModel.get_by_email(info[:email]).nil?
        result[:err] = err_obj(400, $err_types[:DUPLICATE_NOT_ALLOWED], details: { model: 'user' })
        return result
      end

      field_result = exec_field_procs([
        UserValid::Fields.name(info[:user_name]),
        UserValid::Fields.passwd(info[:raw_passwd], info[:config_passwd])
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

    def self.update(id, info)
      result = { is_ok: false }

      if UserModel.get_by_id(id).nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      field_result = exec_field_procs([
        UserValid::Fields.name(info[:user_name])
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

      record = UserModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      unless passwd_correct?(info[:now_passwd], record.passwd, record.salt)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '現在のパスワードが違います')
        return result
      end

      field_result = UserValid::Fields.passwd(info[:new_passwd], info[:new_passwd])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data].nil? ? {} : field_result[:data]
      result[:data][:salt] = record.salt

      result[:is_ok] = true
      result
    end

    def self.delete(id)
      result = { is_ok: false }
      if UserModel.get_by_id(id).nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.login(info)
      result = { is_ok: false }

      if info[:email].nil? || info[:email] == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'メールアドレスは必須です')
        return result
      end

      if info[:passwd].nil? || info[:passwd] == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: 'パスワードは必須です')
        return result
      end

      record = UserModel.get_by_email(info[:email])
      if record.nil?
        result[:err] = err_obj(400, $err_types[:NOT_FOUND], details: { model: 'user' })
        return result
      end

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
