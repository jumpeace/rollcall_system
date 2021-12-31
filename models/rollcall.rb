require './models/student.rb'
require './models/onduty.rb'

class Rollcall < ActiveRecord::Base
end

class RollcallModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    get_result = {}
    # 学生が存在しない場合は無いことを返す
    get_result[:student] = StaffModel.get_by_id(record.student_id, is_format: true)
    return ng_result if get_result[:student].nil?
    
    # 当直が存在しない場合は無いことを返す
    get_result[:onduty] = OndutyModel.get_by_id(record.onduty_id, is_format: true)
    return ng_result if get_result[:onduty].nil?

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    {
      student: get_result[:student],
      staff: get_result[:onduty][:staff],
      time: get_result[:onduty][:time],
      is_student_done: record.is_student_done,
      is_onduty_done: record.is_onduty_done,
      student_img_name: record.student_img_name
    }
  end

  # IDによって点呼表を取得する
  def self.get_by_id(id, is_format: false)
    record = Rollcall.find_by(id: id)
    RollcallModel.get_formatter(record, is_format)
  end
  # 学生と年月日によって点呼表を取得する
  def self.get_by_student_time(student_id, time, is_format: false)
    onduty = OndutyModel.get_by_time(time)
    record = onduty.nil? ? nil : Rollcall.find_by(student_id: student_id, onduty_id: onduty.id)
    RollcallModel.get_formatter(record, is_format)
  end

  # 年月日によって点呼表の一覧を取得する
  def self.gets_by_time(time, is_format: false)
    result = {
      rollcall_count: 0,
      rollcalls: []
    }
    onduty = OndutyModel.get_by_time(time)
    (onduty.nil? ? [] : Rollcall.where(onduty_id: onduty.id)).each do |record|
      result[:rollcalls].push(RollcallModel.get_formatter(record, is_format))
    end

    result[:rollcall_count] = result[:rollcalls].length
    result
  end

  # 点呼表を作成する
  def self.create(info)
    record = Rollcall.new
    record.student_id = info[:student_id]
    record.onduty_id = info[:onduty_id]
    record.save
    record.id
  end

  # 当直によって点呼表を複数作成する
  def self.creates_by_onduty(info)
    StudentModel.gets_all[:students].each do |student|
      RollcallModel.create({ student_id: student.id, onduty_id: info[:onduty_id] })
    end
  end

  # 学籍番号と対応する学生の点呼を行う
  def self.rollcall_today_by_student(student_id, info)
    now = Time.now
    record = RollcallModel.get_by_student_time(student_id, { year: now.year, month: now.month, date: now.day })
    record.is_student_done = true
    record.student_img_name = info[:student_img_name]
    record.save
  end

  # 学籍番号と対応する学生の確認を行う
  def self.check_by_onduty(student_id, time)
    record = RollcallModel.get_by_student_time(student_id, time)
    record.is_onduty_done = true
    record.save
  end

  # 学籍番号と対応する学生の強制確認を行う
  def self.forcedcheck_by_onduty(student_id, time)
    record = RollcallModel.get_by_student_time(student_id, time)
    record.is_student_done = true
    record.is_onduty_done = true
    record.save
  end

  # 学籍番号と対応する学生のやり直しをする
  def self.startover_by_onduty(student_id, time)
    record = RollcallModel.get_by_student_time(student_id, time)
    record.is_student_done = false
    record.is_onduty_done = false
    record.student_img_name = nil
    record.save
  end
end