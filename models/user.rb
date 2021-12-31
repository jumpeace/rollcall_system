

require './helpers/active_record_init.rb'
require './helpers/passwd.rb'

class User < ActiveRecord::Base
end

class UserModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    {
      email: record.email,
      name: record.name
    }
  end

  # IDによってユーザーを取得する
  def self.get_by_id(id, is_format: false)
    record = User.find_by(id: id)
    UserModel.get_formatter(record, is_format)
  end

  # メールアドレスによってユーザーを取得する
  def self.get_by_email(email, is_format: false)
    record = User.find_by(email: email)
    UserModel.get_formatter(record, is_format)
  end

  # ユーザーを作成する
  def self.create(info)
    # ソルトとハッシュ化されたパスワードを生成
    salt, hashed_passwd = passwd_to_hash(info[:raw_passwd])

    record = User.new
    record.email = info[:email]
    record.name = info[:user_name]
    record.is_staff = info[:is_staff]
    record.passwd = hashed_passwd
    record.salt = salt
    record.save

    record.id
  end

  # ユーザーIDと対応するユーザーを更新する
  def self.update(id, info)
    record = UserModel.get_by_id(id)
    record.name = info[:user_name]
    record.save
  end

  # ユーザーIDと対応するユーザーのパスワードを更新する
  def self.update_passwd(id, info)
    hashed_passwd = passwd_to_hash_by_salt(info[:new_passwd], info[:salt])

    record = UserModel.get_by_id(id)
    record.passwd = hashed_passwd
    record.save
  end

  # ユーザーIDと対応するユーザーを削除する
  def self.delete(id)
    record = UserModel.get_by_id(id)
    record.destroy
  end
end
