require './models/user.rb'
require './validations/user.rb'

class UserController
  # パスワードの更新処理
  def self.update_passwd(id, info)
    result = { is_ok: false }

    # バリデーション
    valid_result = UserValid::Procs.update_passwd(id, info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]
    info[:salt] = result[:data][:salt]

    # パスワードの変更処理
    UserModel.update_passwd(id, info)

    result[:is_ok] = true
    result
  end

  # ユーザーが存在するか判定
  def self.user?(id)
    return false if id.nil?

    record = UserModel.get_by_id(id)
    return nil if record.nil?

    record
  end
end
