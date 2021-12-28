require './models/user.rb'
require './valids/user.rb'

class UserController
  def self.create(info)
    result = { is_ok: false }

    valid_result = UserValid::Procs.create(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]

    result[:id] = UserModel.create(info)
    result[:is_ok] = true
    result
  end

  def self.update(id, info)
    result = { is_ok: false }

    valid_result = UserValid::Procs.update(id, info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]

    UserModel.update(id, info)

    result[:is_ok] = true
    result
  end

  def self.update_passwd(id, info)
    result = { is_ok: false }

    valid_result = UserValid::Procs.update_passwd(id, info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]
    info[:salt] = result[:data][:salt]

    UserModel.update_passwd(id, info)

    result[:is_ok] = true
    result
  end

  # def self.delete(id)
  #   result = { is_ok: false }

  #   valid_result = UserValid::Procs.delete(id)
  #   unless valid_result[:is_ok]
  #     result[:err] = valid_result[:err]
  #     return result
  #   end
  #   result[:data] = valid_result[:data]

  #   UserModel.delete(id)

  #   result[:is_ok] = true
  #   result
  # end

  # def self.login(info)
  #   result = { is_ok: false }

  #   valid_result = UserValid::Procs.login(info)
  #   unless valid_result[:is_ok]
  #     result[:err] = valid_result[:err]
  #     return result
  #   end
  #   result[:data] = valid_result[:data]

    # if info[:email].length.zero?
    #   result[:error] = 'メールアドレスを入力してください'
    #   return result
    # end

    # if info[:passwd].length.zero?
    #   result[:error] = 'パスワードを入力してください'
    #   return result
    # end

    # record = {}
    # record[:user] = User.find_by(email: trial_info[:email])
    # if record[:user].nil?
    #   result[:error] = error_mes[:user_not_found]
    #   return result
    # end

    # db_info = {
    #   'user_id': record[:user].id,
    #   'hashed_passwd': record[:user].passwd,
    #   'salt': record[:user].salt
    # }

    # unless passwd_correct?(trial_info[:passwd], db_info[:hashed_passwd], db_info[:salt])
    #   result[:error] = 'パスワードが違います。'
    #   return result
    # end

    # record[:user].last_login_at = Time.now.to_i
    # record[:user].save

  #   result[:id] = UserModel.login(info)

  #   result[:is_ok] = true
  #   result
  # end

  def self.user?(id)
    return false if id.nil?

    record = UserModel.get_by_id(id)
    return nil if record.nil?

    record
  end
end
