require './models/onduty.rb'
require './valids/onduty.rb'
require './controllers/staff.rb'
require './helpers/error.rb'

class OndutyController
  def self.create(info)
    result = { is_ok: false }

    valid_result = OndutyValid::Procs.create(info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    result[:id] = OndutyModel.create(info)
    result[:is_ok] = true
    result
  end

  def self.update(time, info)
    result = { is_ok: false }

    valid_result = OndutyValid::Procs.update(time, info)
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    OndutyModel.update(valid_result[:data][:id], info)

    result[:is_ok] = true
    result
  end

  def self.creating_onday_time
    # { hour: 17, minute: 26 }
    { hour: Time.now.hour, minute: Time.now.min }
  end

  # 当日になったら自動的に追加
  def self.create_onday
    result = {}

    unless OndutyModel.get_today.nil?
      result[:msg] = '今日の当直は既に登録されています'
      return result
    end

    staffs = StaffModel.gets_all[:staffs]
    if staffs.length.zero?
      result[:msg] = 'スタッフが誰もいなかったので、今日の当直を追加できませんでした'
      return result
    end

    admin_staffs = staffs.select { |staff| staff.is_admin }
    selected_staff = admin_staffs.length.positive? ?
      admin_staffs[rand(admin_staffs.length)] : staffs[rand(staffs.length)]

    now = Time.now

    OndutyModel.create({ staff_id: selected_staff.id, time: {
      year: now.year, month: now.month, date: now.day
    } })

    staff = StaffModel.get_by_id(selected_staff.id, is_format: true)
    result[:msg] = "今日の当直がなかったので、#{staff[:user][:name]}（#{staff[:user][:email]}）を当直に追加しました"
    result
  end

  def self.onduty?(user_id, time)
    return false unless StaffController.staff?(user_id)

    staff = StaffModel.get_by_user_id(user_id)
    return false if staff.nil?

    onduty = OndutyModel.get_by_time(time)
    return false if onduty.nil?

    staff.id == onduty.staff_id
  end
end
