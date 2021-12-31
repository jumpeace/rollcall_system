require './helpers/active_record_init.rb'
require './models/building.rb'

class Floor < ActiveRecord::Base
end

class FloorModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format
    
    # プログラム上で扱いやすい形式に変えるときは変えて返す
    get_result = {}
    get_result[:building] = BuildingModel.get_by_num(record.building_num)
    # 号館がない場合は無いことを返す
    return ng_result if get_result[:building].nil?
    
    {
      building_num: get_result[:building].num,
      floor_num: record.floor_num
    }
  end

  # 号館の番号と階の番号によって階を取得する
  def self.get_by_building_floor(building_num, floor_num, is_format: false)
    record = Floor.find_by(building_num: building_num, floor_num: floor_num)
    FloorModel.get_formatter(record, is_format)
  end

  # IDによって階を取得する
  def self.get_by_id(id, is_format: false)
    record = Floor.find_by(id: id)
    FloorModel.get_formatter(record, is_format)
  end

  # 号館の番号に対応する階の一覧を取得する.
  def self.gets_by_building(building_num, is_format: false)
    result = {
      building_num: building_num,
      floor_count: 0,
      floors: []
    }

    Floor.where(building_num: building_num).each do |record|
      result[:floors].push(FloorModel.get_formatter(record, is_format))
    end

    result[:floor_count] = result[:floors].length
    result
  end

  # 階の一覧を取得する
  def self.gets_all(is_format: false)
    result = {
      floor_count: 0,
      floors: []
    }

    Floor.all.each do |record|
      result[:floors].push(FloorModel.get_formatter(record, is_format))
    end

    result[:floor_count] = result[:floors].length
    result
  end
end
