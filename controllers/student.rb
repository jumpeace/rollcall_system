require './models/student.rb'
require './controllers/user.rb'
require './controllers/rollcall.rb'
require './models/rollcall.rb'
require './valids/student.rb'
require './helpers/error.rb'

class StudentController
  def self.create(info)
    result = { is_ok: false }

    valid_result = StudentValid::Procs.create(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    info[:room_id] = valid_result[:data][:room_id]
    info[:hashed_img_name] = valid_result[:data][:hashed_img_name]

    # 画像を保存
    File.open("./public/files/student/#{info[:hashed_img_name]}", 'wb') do |save_fp|
      upload_fp = info[:img][:tempfile]
      write_data = upload_fp.read
      save_fp.write write_data
    end
    # DBに保存
    result[:id] = StudentModel.create(info)
    onduty = OndutyModel.get_today
    # 点呼時間内なら点呼表を追加
    RollcallModel.create({ onduty_id: onduty[:id], student_id: result[:id] }) if (RollcallController.able_rollcall?)

    result[:is_ok] = true
    result
  end

  def self.update(id, info)
    result = { is_ok: false }

    valid_result = StudentValid::Procs.update(id, info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    info[:room_id] = valid_result[:data][:room_id]

    StudentModel.update(id, info)

    result[:is_ok] = true
    result
  end

  def self.update_passwd(id, info)
    result = { is_ok: false }
    get_result = {}
    update_result = {}

    get_result[:student] = StudentModel.get_by_id(id)

    update_result[:passwd] = UserController.update_passwd(get_result[:student].user_id, info)

    unless update_result[:passwd][:is_ok]
      result[:err] = update_result[:passwd][:err]
      return result
    end

    result[:is_ok] = true
    result
  end

  def self.delete(id)
    result = { is_ok: false }

    valid_result = StudentValid::Procs.delete(id)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    StudentModel.delete(id)

    result[:is_ok] = true
    result
  end

  def self.deletes(ids)
    result = { is_ok: false }
    not_found_ids = []

    ids.each do |id|
      delete_result = StudentModel.delete(id)
      not_found_ids.push(id) if !delete_result[:is_ok] && delete_result[:err][:type] == $err_types[:NOT_FOUND]
    end

    unless not_found_ids.length.zero?
      result[:err] = err_obj(404, $err_types[:NOT_FOUND],
        msg: "#{not_found_ids.join(',')}の学生は存在しないため削除できませんでした")
      return result
    end

    result[:is_ok] = true
    result
  end

  def self.login(info)
    result = { is_ok: false }

    valid_result = StudentValid::Procs.login(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]

    result[:is_ok] = true
    result
  end

  def self.student?(user_id)
    return false if user_id.nil?

    user_record = UserModel.get_by_id(user_id)
    return false if user_record.nil?

   !user_record.is_staff
  end
end
