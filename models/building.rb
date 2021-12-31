require './helpers/active_record_init.rb'

class Building < ActiveRecord::Base
end

class BuildingModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format
    
    # プログラム上で扱いやすい形式に変えるときは変えて返す
    { num: record.num }
  end

  # 号館の番号によって号館を取得する
  def self.get_by_num(num, is_format: false)
    record = Building.find_by(num: num)
    BuildingModel.get_formatter(record, is_format)
  end

  # すべての号館の情報を取得する
  def self.gets_all(is_format: false)
    result = {
      count: 0,
      items: []
    }

    records = Building.all
    records.each do |record|
      result[:buildings].push(BuildngModel.get_formatter(record, is_format))
    end

    result[:count] = result[:items].length
    result
  end
end
