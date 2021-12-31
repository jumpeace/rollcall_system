require './helpers/active_record_init.rb'
require './models/user.rb'
require './models/onduty.rb'

class Staff < ActiveRecord::Base
end

class StaffModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    get_result = {}
    get_result[:user] = UserModel.get_by_id(record.user_id, is_format: true)
    {
      id: record.id,
      user: get_result[:user],
      is_admin: record.is_admin
    }
  end

  # IDによってスタッフを取得する
  def self.get_by_id(id, is_format: false)
    record = Staff.find_by(id: id)
    StaffModel.get_formatter(record, is_format)
  end

  # ユーザーIDによってスタッフを取得する
  def self.get_by_user_id(user_id, is_format: false)
    record = Staff.find_by(user_id: user_id)
    StaffModel.get_formatter(record, is_format)
  end

  # スタッフの一覧を取得する
  def self.gets_all(is_format: false)
    result = {
      staff_count: 0,
      staffs: []
    }

    Staff.all.each do |record|
      result[:staffs].push(StaffModel.get_formatter(record, is_format))
    end

    result[:staff_count] = result[:staffs].length
    result
  end

  # スタッフを作成する
  def self.create(info)
    info[:is_staff] = true
    user_id = UserModel.create(info)

    record = Staff.new
    record.user_id = user_id
    record.is_admin = info[:is_admin]
    record.save
    record.id
  end

  # スタッフIDと対応するスタッフを変更する
  def self.update(id, info)
    record = StaffModel.get_by_id(id)
    UserModel.update(record.user_id, info)
  end

  # スタッフIDと対応するスタッフのパスワードを変更する
  def self.update_passwd(id, info)
    record = StaffModel.get_by_id(id)
    UserModel.update_passwd(record.user_id, info)
  end

  # スタッフIDと対応するスタッフを削除する
  def self.delete(id)
    result = { is_ok: false }

    record = Staff.find_by(id: id)

    # 外部キーのリレーションがあるテーブルのレコードを削除
    OndutyModel.deletes_by_staff(record.id)

    UserModel.delete(record.user_id)
    record.destroy

    result[:is_ok] = true
    result
  end
end
