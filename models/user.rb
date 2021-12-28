

require './helpers/active_record_init.rb'
require './helpers/passwd.rb'

class User < ActiveRecord::Base
end

class UserModel
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    return ng_result if record.nil?
    return record unless is_format

    {
      email: record.email,
      name: record.name
    }
  end

  def self.get_by_id(id, is_format: false)
    record = User.find_by(id: id)
    UserModel.get_formatter(record, is_format)
  end

  def self.get_by_email(email, is_format: false)
    record = User.find_by(email: email)
    UserModel.get_formatter(record, is_format)
  end

  def self.create(info)
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

  def self.update(id, info)
    record = UserModel.get_by_id(id)
    record.name = info[:user_name]
    record.save
  end

  def self.update_passwd(id, info)
    hashed_passwd = passwd_to_hash_by_salt(info[:new_passwd], info[:salt])

    record = UserModel.get_by_id(id)
    record.passwd = hashed_passwd
    record.save
  end

  def self.delete(id)
    record = UserModel.get_by_id(id)
    record.destroy
  end
end
