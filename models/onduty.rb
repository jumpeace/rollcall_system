require './models/user.rb'
require './models/staff.rb'
require './helpers/error.rb'
require './helpers/time.rb'

class Onduty < ActiveRecord::Base
end

class OndutyModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    get_result = {}
    get_result[:staff] = StaffModel.get_by_id(record.staff_id, is_format: true)

    {
      staff: get_result[:staff],
      time: {
        year: record.year,
        month: record.month,
        date: record.date,
        to_str: "#{record.year}年#{record.month}月#{record.date}日"
      }
    }
  end

  # IDによって当直を取得する
  def self.get_by_id(id, is_format: false)
    record = Onduty.find_by(id: id)
    OndutyModel.get_formatter(record, is_format)
  end

  # 年月日によって当直を取得する
  def self.get_by_time(time, is_format: false)
    record = Onduty.find_by(year: time[:year], month: time[:month], date: time[:date])
    OndutyModel.get_formatter(record, is_format)
  end

  # 当日のによって当直を取得する
  def self.get_today(is_format: false)
    now = Time.now
    OndutyModel.get_by_time({ year: now.year, month: now.month, date: now.day }, is_format: is_format)
  end

  # 年月によって当直を取得する
  def self.gets_by_year_month(year, month, is_format: false)
    result = {
      onduty_count: 0,
      onduties: []
    }

    Onduty.where(year: year, month: month).each do |record|
      result[:onduties].push(OndutyModel.get_formatter(record, is_format))
    end

    result[:onduty_count] = result[:onduties].length
    result
  end

  # 現在以降の当直の一覧を取得する
  def self.gets_by_staff_now_future(staff_id, is_format: false)
    result = {
      onduty_count: 0,
      onduties: []
    }

    Onduty.where(staff_id: staff_id).each do |record|
      next if MyTime.compare_day(record.year, record.month, record.date) == 'past'

      result[:onduties].push(OndutyModel.get_formatter(record, is_format))
    end

    result[:onduty_count] = result[:onduties].length
    result
  end

  # スタッフと対応する当直を取得する
  def self.gets_by_staff(staff_id, is_format: false)
    result = {
      onduty_count: 0,
      onduties: []
    }

    Onduty.where(staff_id: staff_id).each do |record|
      result[:onduties].push(OndutyModel.get_formatter(record, is_format))
    end

    result[:onduty_count] = result[:onduties].length
    result
  end

  # 当直の一覧を取得する
  def self.gets_all(is_format: false)
    result = {
      onduty_count: 0,
      onduties: []
    }

    Onduty.all.each do |record|
      OndutyModel.get_formatter(record, is_format)
    end

    result[:onduty_count] = result[:onduties].length
    result
  end

  # 当直を作成する
  def self.create(info)
    record = Onduty.new
    record.staff_id = info[:staff_id]
    record.year = info[:time][:year]
    record.month = info[:time][:month]
    record.date = info[:time][:date]
    record.save
    record.id
  end

  # 当直IDと対応する当直を変更する
  def self.update(id, info)
    record = OndutyModel.get_by_id(id)
    record.staff_id = info[:staff_id]
    record.save
  end

  # スタッフと対応する当直を削除する
  def self.deletes_by_staff(staff_id)
    OndutyModel.gets_by_staff(staff_id)[:onduties].each do |record|
      record.destroy
    end
  end
end
