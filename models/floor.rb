require './helpers/active_record_init.rb'
require './models/building.rb'

class Floor < ActiveRecord::Base
end

class FloorModel
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    return ng_result if record.nil?
    return record unless is_format

    get_result = {}
    get_result[:building] = BuildingModel.get_by_num(record.building_num)
    return ng_result if get_result[:building].nil?

    {
      building_num: get_result[:building].num,
      floor_num: record.floor_num
    }
  end

  def self.get_by_building_floor(building_num, floor_num, is_format: false)
    record = Floor.find_by(building_num: building_num, floor_num: floor_num)
    FloorModel.get_formatter(record, is_format)
  end

  def self.get_by_id(id, is_format: false)
    record = Floor.find_by(id: id)
    FloorModel.get_formatter(record, is_format)
  end

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
