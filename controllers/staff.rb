require './models/staff.rb'
require './controllers/user.rb'
require './valids/staff.rb'
require './helpers/error.rb'

class StaffController
  # スタッフの作成処理
  def self.create(info, is_admin: false)
    result = { is_ok: false }

    # バリデーション
    valid_result = StaffValid::Procs.create(info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    info[:is_admin] = is_admin

    # スタッフの作成処理
    result[:id] = StaffModel.create(info)

    result[:is_ok] = true
    result
  end

  # 通常のスタッフの作成処理
  def self.create_normal(info)
    # スタッフの作成処理を利用
    StaffController.create(info)
  end
  
  # 管理者のスタッフの作成処理を行う
  def self.create_admin(info)
    # スタッフの作成処理を利用
    info[:config_passwd] = info[:raw_passwd]
    StaffController.create(info, is_admin: true)
  end

  # スタッフIDに対応するスタッフの変更処理
  def self.update(id, info)
    result = { is_ok: false }

    # バリデーション
    valid_result = StaffValid::Procs.update(id, info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # スタッフの変更処理
    StaffModel.update(id, info)

    result[:is_ok] = true
    result
  end

  # スタッフIDに対応するスタッフのパスワードの変更処理
  def self.update_passwd(id, info)
    result = { is_ok: false }
    get_result = {}
    update_result = {}

    # パスワードを変更するスタッフのレコードを取得
    get_result[:staff] = StaffModel.get_by_id(id)

    # ユーザーのControllerでパスワードの変更処理を行う
    update_result[:passwd] = UserController.update_passwd(get_result[:staff].user_id, info)

    # パスワードの変更処理が失敗した場合
    unless update_result[:passwd][:is_ok]
      result[:err] = update_result[:passwd][:err]
      return result
    end

    result[:is_ok] = true
    result
  end

  # スタッフIDに対応するスタッフの削除処理
  def self.delete(id)
    result = { is_ok: false }

    # バリデーション
    valid_result = StaffValid::Procs.delete(id)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # バリデーションが成功した場合, 学生に対応する学生を削除する
    StaffModel.delete(id)

    result[:is_ok] = true
    result
  end

  # 複数のスタッフの削除処理
  def self.deletes(ids)
    result = { is_ok: false }
    not_found_ids = []
    not_allowed_ids = []

    # スタッフIDのスタッフの削除処理
    ids.each do |id|
      delete_result = StaffController.delete(id)
      unless delete_result[:is_ok]
        not_found_ids.push(id) if delete_result[:err][:type] == $err_types[:NOT_FOUND]
        not_allowed_ids.push(id) if delete_result[:err][:type] == $err_types[:PROCESS_NOT_ALLOWED]
      end
    end

    result[:errs] = []
    # 一人以上のスタッフが見つからなくて削除できなかった場合
    unless not_found_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "#{not_found_ids.join(',')}のスタッフは存在しないため削除できませんでした"))
    end
    # 一人以上のスタッフが管理者のため削除できなかった場合
    unless not_allowed_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "#{not_allowed_ids.join(',')}のスタッフは管理者のため削除できませんでした"))
    end

    return result if result[:errs].length.positive?

    result[:is_ok] = true
    result
  end

  # スタッフのログイン処理
  def self.login(info)
    result = { is_ok: false }

    # バリデーション
    valid_result = StaffValid::Procs.login(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]

    # バリデーションが成功したらログイン処理を行う（実際のログイン処理は main.rb で行う）
    result[:is_ok] = true
    result
  end

  # ユーザーがスタッフかどうか判定する
  def self.staff?(user_id)
    return false if user_id.nil?

    user_record = UserModel.get_by_id(user_id)
    return false if user_record.nil?

    user_record.is_staff
  end

  # ユーザーが通常のスタッフかどうか判定する
  def self.normal_staff?(user_id)
    return false unless staff?(user_id)

    record = StaffModel.get_by_user_id(user_id)
    return false if record.nil?

    !record.is_admin
  end

  # ユーザーが管理者のスタッフかどうか判定する
  def self.admin_staff?(user_id)
    return false unless staff?(user_id)

    record = StaffModel.get_by_user_id(user_id)
    return false if record.nil?

    record.is_admin
  end
end
