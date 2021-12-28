require './models/student.rb'
require './valids/user.rb'
require './valids/helpers.rb'
require './helpers/error.rb'
require './helpers/base.rb'
require 'digest/md5'

class StudentValid
  class Fields
    def self.id(id)
      result = { is_ok: false }

      if id.nil? || id == ''
        result[:err] = err_obj(400, $err_types[:NOT_FOUND], msg: '学籍番号は必須です')
        return result
      end

      unless id.match(/^\d{5}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '学籍番号を正しいフォーマットで入力してください（数字5桁）')
        return result
      end

      department_id = id[2].to_i
      unless department_id >= 1 && department_id <= 5
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '3桁目は1～5で入力してください')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.grade(grade)
      result = { is_ok: false }

      if grade.nil? || grade == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '学年は必須です')
        return result
      end

      unless grade.to_i >= 1 && grade.to_i <= 5
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '学年を正しいフォーマットで入力してください（1～5の数字）')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.department_id(department_id)
      result = { is_ok: false }

      if department_id.nil? || department_id == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '学科は必須です')
        return result
      end

      gets_result = DepartmentModel.gets_all[:departments]
      unless gets_result.any? { |department| department_id.to_i == department[:id]}
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '正しい学科が入力されていません')
        return result
      end

      result[:is_ok] = true
      result
    end

    def self.room_num(room_num, id: nil)
      result = { is_ok: false }
      get_result = {}

      if room_num.nil? || room_num == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '部屋番号は必須です')
        return result
      end

      room_num_i = room_num.to_i
      if room_num.match(/^\d{5}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '部屋番号を正しいフォーマットで入力してください（数字4桁）')
        return result
      end

      get_result[:building] = BuildingModel.get_by_num(get_num_by_digit(room_num_i, 0))
      if get_result[:building].nil?
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg:  '号館がおかしいです')
        return result
      end

      get_result[:floor] = FloorModel.get_by_building_floor(get_result[:building].num, get_num_by_digit(room_num_i, 1))
      if get_result[:floor].nil?
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '階がおかしいです')
        return result
      end

      get_result[:room] = RoomModel.get_by_floor_room(get_result[:floor].id, get_num_by_digit(room_num_i, 2, 2))
      if get_result[:room].nil?
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '部屋がおかしいです')
        return result
      end

      is_same_room = false
      unless id.nil?
        record_by_id = StudentModel.get_by_id(id)
        is_same_room = true if !record_by_id.nil? && record_by_id.room_id == get_result[:room][:id]
        p 'record_by_id', id, record_by_id
      end
      # TODO 満員だったら予測変換を表示しない
      unless is_same_room
        room_person_count =  StudentModel.gets_by_room(get_result[:room].id)[:student_count]
        if room_person_count >= get_result[:room].person_max
          result[:err] = err_obj(400, $err_types[:VALID_ERR],
            msg: "#{room_num}号室は満員です。（#{room_person_count} / #{get_result[:room].person_max}）")
          return result
        end
      end

      result[:data] = {
        room_id: get_result[:room].id
      }

      result[:is_ok] = true
      result
    end

    def self.img(img)
      result = { is_ok: false }

      if img.nil?
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '画像をアップロードしてください')
        return result
      end

      result[:data] = {
        hashed_img_name: "#{SecureRandom.hex(16)}.#{img[:filename].split('.')[-1]}"
      }
      result[:is_ok] = true
      result
    end
  end

  class Procs
    def self.create(info)
      result = { is_ok: false }
      data = {}

      field_result = exec_field_procs([
        StudentValid::Fields.id(info[:student_id])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])
      info[:email] = "#{info[:student_id]}@g.nagano-nct.ac.jp"

      field_result = exec_field_procs([
        UserValid::Procs.create(info)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:DUPLICATE_NOT_ALLOWED] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応する学生はすでにいます' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      data = data.merge(field_result[:data])

      field_result = exec_field_procs([
        UserValid::Procs.create(info),
        StudentValid::Fields.grade(info[:grade]),
        StudentValid::Fields.department_id(info[:department_id]),
        StudentValid::Fields.room_num(info[:room_num]),
        StudentValid::Fields.img(info[:img])
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      result[:data] = data
      result[:is_ok] = true
      result
    end

    def self.update(id, info)
      p 'valid', id, info
      result = { is_ok: false }

      record = StudentModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: '学籍番号と対応する学生がいません')
        return result
      end

      field_result = exec_field_procs([
        UserValid::Procs.update(record.user_id, info),
        StudentValid::Fields.grade(info[:grade]),
        StudentValid::Fields.department_id(info[:department_id]),
        StudentValid::Fields.room_num(info[:room_num], id: id)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    def self.update_passwd(id, info)
      result = { is_ok: false }

      record = StudentModel.get_By_id(id)
      field_result = exec_field_procs([
        UserValid::Procs.update_passwd(record.user_id, info)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    def self.delete(id)
      result = { is_ok: false }

      record = StudentModel.get_By_id(id)
      field_result = exec_field_procs([
        UserValid::Procs.delete(record.user_id)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応するスタッフがいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    def self.login(info)
      result = { is_ok: false }
      if info[:id] == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '学籍番号は必須です')
        return result
      end

      info[:email] = "#{info[:id]}@g.nagano-nct.ac.jp"
      field_result = exec_field_procs([
        UserValid::Procs.login(info)
      ])
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応する学生はいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end
  end
end
