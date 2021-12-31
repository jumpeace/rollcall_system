require './helpers/active_record_init.rb'
require './models/floor.rb'

class Room < ActiveRecord::Base
end

class RoomModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    get_result = {}
    get_result[:floor] = FloorModel.get_by_id(record.floor_id)
    # 階がない場合は階が無いことを返す
    return ng_result if get_result[:floor].nil?

    {
      floor: get_result[:floor],
      room_num: record.room_num,
      room: "#{get_result[:floor][:building_num]}#{get_result[:floor][:floor_num]}#{'%02d' % record.room_num}",
      person_max: record.person_max
    }
  end

  # 階のIDと部屋の下2桁によって階を取得する
  def self.get_by_floor_room(floor_id, room_num, is_format: false)
    record = Room.find_by(floor_id: floor_id, room_num: room_num)
    RoomModel.get_formatter(record, is_format)
  end

  # 号館の番号と階の番号部屋の下2桁によって階を取得する
  def self.get_by_building_floor_room(building_num, floor_num, room_num, is_format: false)
    get_result = {}

    get_result[:floor] = FloorModel.get_by_floor_room(building_num, floor_num)
    return result if get_result[:floor].nil?

    RoomModel.get_formatter(Room.find_by(floor_id: get_result[:floor].id, room_num: room_num), is_format)
  end

  # IDによっ部屋を取得する
  def self.get_by_id(id, is_format: false)
    record = Room.find_by(id: id)
    RoomModel.get_formatter(record, is_format)
  end

  # 階のIDによって部屋を複数取得する
  def self.gets_by_floor_id(floor_id, is_format: false)
    result = {
      room_count: 0,
      rooms: []
    }

    get_result = {}
    get_result[:floor] = FloorModel.get_by_id(floor_id)
    return result if get_result[:floor].nil?

    Room.where(floor_id: get_result[:floor].id).each do |record|
      result[:rooms].push(RoomModel.get_formatter(record, is_format))
    end

    result[:room_count] = result[:rooms].length
    result
  end

  # 号館の番号と階の番号と部屋の下2桁によって部屋を複数取得する
  def self.gets_by_building_floor(building_num, floor_num, is_format: false)
    result = {
      building_num: building_num,
      floor_num: floor_num,
      room_count: 0,
      rooms: []
    }

    get_result = {}
    get_result[:floor] = FloorModel.get_by_building_floor(building_num, floor_num)
    return result if get_result[:floor].nil?

    Room.where(floor_id: get_result[:floor].id).each do |record|
      result[:rooms].push(RoomModel.get_formatter(record, is_format))
    end

    result[:room_count] = result[:rooms].length
    result
  end

  # 強姦の番号と階の番号と部屋の下2桁目によって部屋を複数取得する
  def self.gets_by_building_floor_digit_ten(building_num, floor_num, digit_ten, is_format: false)
    result = {
      building_num: building_num,
      floor_num: floor_num,
      room_count: 0,
      rooms: []
    }

    get_result = {}
    # 階を取得
    get_result[:floor] = FloorModel.get_by_building_floor(building_num, floor_num)
    return result if get_result[:floor].nil?

    Room.where(floor_id: get_result[:floor].id).each do |record|
      next if !digit_ten.nil? && digit_ten != (record.room_num / 10).to_i
      result[:rooms].push(RoomModel.get_formatter(record, is_format))
    end

    result[:room_count] = result[:rooms].length
    result
  end
end
