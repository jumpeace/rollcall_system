require './models/onduty.rb'
require './validations/onduty.rb'
require './controllers/staff.rb'
require './helpers/error.rb'

class OndutyController
  # 当直の作成処理
  def self.create(info)
    result = { is_ok: false }

    # バリデーション
    valid_result = OndutyValid::Procs.create(info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # 当直の作成処理
    result[:id] = OndutyModel.create(info)
    result[:is_ok] = true
    result
  end

  # 当直の変更処理
  def self.update(time, info)
    result = { is_ok: false }

    # バリデーション
    valid_result = OndutyValid::Procs.update(time, info)
    # バリデーションが失敗した場合は処理を行わない
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # 当直の変更処理
    OndutyModel.update(valid_result[:data][:id], info)

    result[:is_ok] = true
    result
  end

  # 当日の当直を自動で作成する時間（夜の0時）を取得
  def self.creating_onday_time
    { hour: 0, minute: 0 }
  end

  # 当日の夜0時に当直を自動的に追加
  def self.create_onday
    result = {}

    # 当直がすでに追加されている場合は当直を追加しない
    unless OndutyModel.get_today.nil?
      result[:msg] = '今日の当直は既に登録されています'
      return result
    end

    # スタッフが誰もいなかった場合は当直を追加しない
    staffs = StaffModel.gets_all[:staffs]
    if staffs.length.zero?
      result[:msg] = 'スタッフが誰もいなかったので、今日の当直を追加できませんでした'
      return result
    end

    # 管理者の中でランダムに当直を選ぶ
    # 管理者がいなかった場合は普通のスタッフからランダムに選ぶ
    admin_staffs = staffs.select { |staff| staff.is_admin }
    selected_staff = admin_staffs.length.positive? ?
      admin_staffs[rand(admin_staffs.length)] : staffs[rand(staffs.length)]

    # 当直の追加処理を行う
    now = Time.now
    OndutyModel.create({ staff_id: selected_staff.id, time: {
      year: now.year, month: now.month, date: now.day
    } })

    staff = StaffModel.get_by_id(selected_staff.id, is_format: true)
    result[:msg] = "今日の当直がなかったので、#{staff[:user][:name]}（#{staff[:user][:email]}）を当直に追加しました"
    result
  end

  # ユーザーが指定された日にちの当直か判定する
  def self.onduty?(user_id, time)
    return false unless StaffController.staff?(user_id)

    staff = StaffModel.get_by_user_id(user_id)
    return false if staff.nil?

    onduty = OndutyModel.get_by_time(time)
    return false if onduty.nil?

    staff.id == onduty.staff_id
  end
end
