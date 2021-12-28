require './models/staff.rb'
require './controllers/user.rb'
require './valids/staff.rb'
require './helpers/error.rb'

class StaffController
  def self.create(info, is_admin: false)
    result = { is_ok: false }

    valid_result = StaffValid::Procs.create(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    # info[:is_teacher] = valid_result[:data][:is_teacher]
    info[:is_admin] = is_admin
    result[:id] = StaffModel.create(info)

    result[:is_ok] = true
    result
  end

  def self.create_normal(info)
    StaffController.create(info)
  end

  def self.create_admin(info)
    info[:config_passwd] = info[:raw_passwd]
    StaffController.create(info, is_admin: true)
  end

  def self.update(id, info)
    result = { is_ok: false }

    valid_result = StaffValid::Procs.update(id, info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    StaffModel.update(id, info)

    result[:is_ok] = true
    result
  end

  # def self.update_passwd(id, info)
  #   result = { is_ok: false }

  #   valid_result = StaffValid::Procs.update_passwd(id, info)
  #   unless valid_result[:is_ok]
  #     result[:err] = valid_result[:err]
  #     return result
  #   end

  #   StaffModel.update_passwd(id, info)

  #   result[:is_ok] = true
  #   result
  # end

  def self.update_passwd(id, info)
    result = { is_ok: false }
    get_result = {}
    update_result = {}

    get_result[:staff] = StaffModel.get_by_id(id)

    update_result[:passwd] = UserController.update_passwd(get_result[:staff].user_id, info)

    unless update_result[:passwd][:is_ok]
      result[:err] = update_result[:passwd][:err]
      return result
    end

    result[:is_ok] = true
    result
  end

  def self.delete(id)
    result = { is_ok: false }

    valid_result = StaffValid::Procs.delete(id)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    StaffModel.delete(id)

    result[:is_ok] = true
    result
  end

  def self.deletes(ids)
    result = { is_ok: false }
    not_found_ids = []
    not_allowed_ids = []

    ids.each do |id|
      delete_result = StaffController.delete(id)
      unless delete_result[:is_ok]
        not_found_ids.push(id) if delete_result[:err][:type] == $err_types[:NOT_FOUND]
        not_allowed_ids.push(id) if delete_result[:err][:type] == $err_types[:PROCESS_NOT_ALLOWED]
      end
    end

    result[:errs] = []
    unless not_found_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "#{not_found_ids.join(',')}のスタッフは存在しないため削除できませんでした"))
    end
    unless not_allowed_ids.length.zero?
      result[:errs].push(err_obj(404, $err_types[:NOT_FOUND],
        msg: "#{not_allowed_ids.join(',')}のスタッフは管理者のため削除できませんでした"))
    end

    return result if result[:errs].length.positive?

    result[:is_ok] = true
    result
  end

  def self.login(info)
    result = { is_ok: false }

    valid_result = StaffValid::Procs.login(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]

    result[:is_ok] = true
    result
  end

  def self.staff?(user_id)
    return false if user_id.nil?

    user_record = UserModel.get_by_id(user_id)
    return false if user_record.nil?

    user_record.is_staff
  end

  def self.normal_staff?(user_id)
    return false unless staff?(user_id)

    record = StaffModel.get_by_user_id(user_id)
    return false if record.nil?

    !record.is_admin
  end

  def self.admin_staff?(user_id)
    return false unless staff?(user_id)

    record = StaffModel.get_by_user_id(user_id)
    return false if record.nil?

    record.is_admin
  end
end
