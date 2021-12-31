require './helpers/active_record_init.rb'
require './models/user.rb'
require './models/department.rb'
require './models/floor.rb'
require './models/room.rb'

class Student < ActiveRecord::Base
end

class StudentModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    get_result = {}

    get_result[:user] = UserModel.get_by_id(record.user_id, is_format: true)
    get_result[:department] = DepartmentModel.get_by_id(record.department_id, is_format: true)
    get_result[:room] = RoomModel.get_by_id(record.room_id, is_format: true)

    {
      id: record.id,
      user: get_result[:user],
      grade: record.grade,
      department:  get_result[:department],
      room: get_result[:room],
      img_name: record.img_name
    }
  end

  # IDによって学生を取得する
  def self.get_by_id(id, is_format: false)
    record = Student.find_by(id: id)
    StudentModel.get_formatter(record, is_format)
  end

  # ユーザーIDによって学生を取得する
  def self.get_by_user_id(user_id, is_format: false)
    record = Student.find_by(user_id: user_id)
    StudentModel.get_formatter(record, is_format)
  end

  # 号館の番号と階の番号によって複数の学生を取得する
  def self.gets_by_building_floor(building_num, floor_num, is_format: false)
    result = {
      building_num: building_num,
      floor_num: floor_num,
      student_count: 0,
      students: []
    }

    get_result = {}
    # 階を取得する
    get_result[:floor] = FloorModel.get_by_building_floor(building_num, floor_num)
    return result if get_result[:floor].nil?

    RoomModel.gets_by_floor_id(get_result[:floor].id)[:rooms].each do |room|
      Student.where(room_id: room.id).each do |record|
        result[:students].push(StudentModel.get_formatter(record, is_format))
      end
    end

    result[:student_count] = result[:students].length
    result
  end

  # 部屋IDによって学生を取得する
  def self.gets_by_room(room_id, is_format: false)
    result = {
      student_count: 0,
      students: []
    }

    Student.where(room_id: room_id).each do |record|
      result[:students].push(StaffModel.get_formatter(record, is_format))
    end

    result[:student_count] = result[:students].length
    result
  end

  # 学生一覧を取得する
  def self.gets_all(is_format: false)
    result = {
      student_count: 0,
      students: []
    }

    Student.all.each do |record|
      result[:students].push(StudentModel.get_formatter(record, is_format))
    end

    result[:student_count] = result[:students].length
    result
  end

  # 学生を作成する
  def self.create(info)
    # 学籍番号からメールアドレスを取得する
    info[:email] = "#{info[:student_id]}@g.nagano-nct.ac.jp"
    info[:is_staff] = false
    user_id = UserModel.create(info)

    record = Student.new
    record.id = info[:student_id]
    record.user_id = user_id
    record.grade = info[:grade]
    record.department_id = info[:department_id]
    record.room_id = info[:room_id]
    record.img_name = info[:hashed_img_name]
    record.save

    record.id
  end

  # 学籍番号と対応する学生を変更する
  def self.update(id, info)
    result = { is_ok: false }

    record = StudentModel.get_by_id(id)
    UserModel.update(record.user_id, info)

    record.grade = info[:grade]
    record.department_id = info[:department_id]
    record.room_id = info[:room_id]
    record.save

    result[:is_ok] = true
    result
  end

  # 学籍番号と対応する学生を削除する
  def self.delete(id)
    result = { is_ok: false }

    record = Student.find_by(id: id)

    UserModel.delete(record.user_id)

    record.destroy

    result[:is_ok] = true
    result
  end

  # 学籍番号と対応する複数の学生を削除する
  def self.deletes(ids)
    result = { not_found_ids: [] }
    delete_result = {}

    ids.each do |id|
      delete_result[:student] = StudentModel.delete(id)
      unless delete_result[:is_ok]
        if delete_result[:err][:type] == 'Not Found'
          result[:not_found_ids].push(id)
        end
      end
    end

    result
  end
end
