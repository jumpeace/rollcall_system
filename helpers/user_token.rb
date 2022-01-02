require 'digest/md5'
require './helpers/active_record_init.rb'

class UserToken < ActiveRecord::Base
end

# ユーザートークンの生成
def get_user_token(user_id)
  token = SecureRandom.hex(16) + Digest::MD5.hexdigest(user_id.to_s)

  record = UserToken.new
  record.id = token
  record.user_id = user_id
  # ユーザートークンの有効期限は20分
  record.expired_at = Time.now.to_i + 1200
  record.save

  token
end

# ユーザートークンが正しいか判定
def valid_user_token?(trial_token, user_id)
  record = UserToken.find_by(id: trial_token)
  # ユーザートークンと対応するレコードがなかったら無効
  return false if record.nil?
  # ユーザーIDが異なっていたら無効
  return false if record.user_id != user_id
  # 有効期限が過ぎていたら無効
  return false if Time.now.to_i > record.expired_at

  true
end
