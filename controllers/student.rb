require './models/student.rb'
require './controllers/user.rb'
require './controllers/rollcall.rb'
require './models/rollcall.rb'
require './valids/student.rb'
require './helpers/error.rb'

class StudentController
  # 学生の作成処理
  def self.create(info)
    result = { is_ok: false }

    # バリデーション
    valid_result = StudentValid::Procs.create(info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    info[:room_id] = valid_result[:data][:room_id]
    info[:hashed_img_name] = valid_result[:data][:hashed_img_name]

    # 学生の画像を保存
    File.open("./public/files/student/#{info[:hashed_img_name]}", 'wb') do |save_fp|
      upload_fp = info[:img][:tempfile]
      write_data = upload_fp.read
      save_fp.write write_data
    end

    # 学生の作成処理
    result[:id] = StudentModel.create(info)
    onduty = OndutyModel.get_today
    # 点呼時間内なら点呼表を追加
    RollcallModel.create({ onduty_id: onduty[:id], student_id: result[:id] }) if (RollcallController.able_rollcall?)

    result[:is_ok] = true
    result
  end

  # 学籍番号に対応する学生の変更処理
  def self.update(id, info)
    result = { is_ok: false }

    # バリデーション
    valid_result = StudentValid::Procs.update(id, info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    info[:room_id] = valid_result[:data][:room_id]

    # 学生の変更処理を行う
    StudentModel.update(id, info)

    result[:is_ok] = true
    result
  end

  # 学籍番号に対応する学生のパスワードの変更処理
  def self.update_passwd(id, info)
    result = { is_ok: false }
    get_result = {}
    update_result = {}

    # パスワードを変更する学生のレコードを取得
    get_result[:student] = StudentModel.get_by_id(id)

    # ユーザーのControllerでパスワードの変更処理を行う
    update_result[:passwd] = UserController.update_passwd(get_result[:student].user_id, info)

    # パスワードの変更処理が失敗した場合
    unless update_result[:passwd][:is_ok]
      result[:err] = update_result[:passwd][:err]
      return result
    end

    result[:is_ok] = true
    result
  end

  # 学籍番号に対応するの学生の削除処理
  def self.delete(id)
    result = { is_ok: false }

    # バリデーション
    valid_result = StudentValid::Procs.delete(id)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # バリデーションが成功した場合, 学籍番号に対応する学生を削除する
    StudentModel.delete(id)

    result[:is_ok] = true
    result
  end

  # 複数の学生の削除処理
  def self.deletes(ids)
    result = { is_ok: false }
    not_found_ids = []

    # 学籍番号ごとに学生の削除処理を行う
    ids.each do |id|
      delete_result = StudentModel.delete(id)
      not_found_ids.push(id) if !delete_result[:is_ok] && delete_result[:err][:type] == $err_types[:NOT_FOUND]
    end

    # 一人以上の学生が見つからなくて削除できなかった場合
    unless not_found_ids.length.zero?
      result[:err] = err_obj(404, $err_types[:NOT_FOUND],
        msg: "#{not_found_ids.join(',')}の学生は存在しないため削除できませんでした")
      return result
    end

    result[:is_ok] = true
    result
  end

  # 学生のログイン処理
  def self.login(info)
    result = { is_ok: false }

    # バリデーション
    valid_result = StudentValid::Procs.login(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end
    result[:data] = valid_result[:data]

    # バリデーションが成功したらログイン処理を行う（実際のログイン処理は main.rb で行う）
    result[:is_ok] = true
    result
  end

  # ユーザーが学生かどうか判定する
  def self.student?(user_id)
    return false if user_id.nil?

    user_record = UserModel.get_by_id(user_id)
    return false if user_record.nil?

    !user_record.is_staff
  end
end
