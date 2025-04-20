require './models/student.rb'
require './validations/user.rb'
require './validations/helpers.rb'
require './helpers/error.rb'
require './helpers/base.rb'
require 'digest/md5'

class StudentValid
  class Fields
    # 学籍番号でのバリデーション
    def self.id(id)
      result = { is_ok: false }

      # 学籍番号が入力されていない場合はバリデーション失敗
      if id.nil? || id == ''
        result[:err] = err_obj(400, $err_types[:NOT_FOUND], msg: '学籍番号は必須です')
        return result
      end

      # 学籍番号が数字5桁でない場合はバリデーション失敗
      unless id.match(/^\d{5}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '学籍番号を正しいフォーマットで入力してください（数字5桁）')
        return result
      end

      department_id = id[2].to_i
      # 学籍番号の学科の部分が正しくない場合はバリデーション失敗
      unless department_id >= 1 && department_id <= 5
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '3桁目は1～5で入力してください')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 学年でのバリデーション
    def self.grade(grade)
      result = { is_ok: false }

      # 学年が入力されていない場合はバリデーション失敗
      if grade.nil? || grade == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '学年は必須です')
        return result
      end

      # 学年が1から5の整数でない場合はバリデーション失敗
      unless grade.to_i >= 1 && grade.to_i <= 5
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '学年を正しいフォーマットで入力してください（1～5の数字）')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 学科でのバリデーション
    def self.department_id(department_id)
      result = { is_ok: false }

      # 学科が入力されていない場合はバリデーション失敗
      if department_id.nil? || department_id == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '学科は必須です')
        return result
      end

      # 正しい学科が入力されていない場合はバリデーション失敗
      gets_result = DepartmentModel.gets_all[:departments]
      unless gets_result.any? { |department| department_id.to_i == department[:id]}
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '正しい学科が入力されていません')
        return result
      end

      result[:is_ok] = true
      result
    end

    # 部屋でのバリデーション
    def self.room_num(room_num, id: nil)
      result = { is_ok: false }
      get_result = {}

      # 部屋番号が入力されていない場合はバリデーション失敗
      if room_num.nil? || room_num == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '部屋番号は必須です')
        return result
      end

      room_num_i = room_num.to_i
      # 部屋番号が数字4桁で入力されていない場合はバリデーション失敗
      if room_num.match(/^\d{4}$/)
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '部屋番号を正しいフォーマットで入力してください（数字4桁）')
        return result
      end

      # 号館が正しくない場合はバリデーション失敗
      get_result[:building] = BuildingModel.get_by_num(get_num_by_digit(room_num_i, 0))
      if get_result[:building].nil?
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg:  '号館がおかしいです')
        return result
      end

      # 階が正しくない場合はバリデーション失敗
      get_result[:floor] = FloorModel.get_by_building_floor(get_result[:building].num, get_num_by_digit(room_num_i, 1))
      if get_result[:floor].nil?
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '階がおかしいです')
        return result
      end

      # 部屋番号の下2桁が正しくない場合はバリデーション失敗
      get_result[:room] = RoomModel.get_by_floor_room(get_result[:floor].id, get_num_by_digit(room_num_i, 2, 2))
      if get_result[:room].nil?
        result[:err] = err_obj(400, $err_types[:VALID_ERR], msg: '部屋がおかしいです')
        return result
      end

      # 学生の変更処理で変更する学生の部屋番号が変更前の部屋番号と同じかどうか
      is_same_room = false
      unless id.nil?
        record_by_id = StudentModel.get_by_id(id)
        is_same_room = true if !record_by_id.nil? && record_by_id.room_id == get_result[:room][:id]
      end

      # 学生の変更処理で変更する学生の部屋番号が変更前の部屋番号と同じ出ない場合
      unless is_same_room
        room_person_count =  StudentModel.gets_by_room(get_result[:room].id)[:student_count]
        # 部屋が満員の場合
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

    # 学生の画像でのバリデーション
    def self.img(img)
      result = { is_ok: false }

      # 画像がない場合はバリデーション失敗
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
    # 学生を作成するときのバリデーション
    def self.create(info)
      result = { is_ok: false }
      data = {}

      # 学籍番号でのバリデーション
      field_result = format_field_results([
        StudentValid::Fields.id(info[:student_id])
      ])
      # 学籍番号でのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])
      # メールアドレスを学籍番号から取得
      info[:email] = "#{info[:student_id]}@g.nagano-nct.ac.jp"

      # ユーザーを作成するときのバリデーション
      field_result = format_field_results([
        UserValid::Procs.create(info)
      ])
      # ユーザーを作成するときのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがすでにいた場合, エラーメッセージを学生用に書き換える
        if result[:err][:type] == $err_types[:DUPLICATE_NOT_ALLOWED] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応する学生はすでにいます' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      data = data.merge(field_result[:data])

      # カラムごとのバリデーション
      field_result = format_field_results([
        StudentValid::Fields.grade(info[:grade]),
        StudentValid::Fields.department_id(info[:department_id]),
        StudentValid::Fields.room_num(info[:room_num]),
        StudentValid::Fields.img(info[:img])
      ])
      # カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      data = data.merge(field_result[:data])

      result[:data] = data
      result[:is_ok] = true
      result
    end

    # 学生を変更するときのバリデーション
    def self.update(id, info)
      result = { is_ok: false }

      # 学籍番号と対応する学生がいなかった場合はバリデーション失敗
      record = StudentModel.get_by_id(id)
      if record.nil?
        result[:err] = err_obj(404, $err_types[:NOT_FOUND], msg: '学籍番号と対応する学生がいません')
        return result
      end

      # ユーザー変更時のバリデーション, カラムごとのバリデーション
      field_result = format_field_results([
        UserValid::Procs.update(record.user_id, info),
        StudentValid::Fields.grade(info[:grade]),
        StudentValid::Fields.department_id(info[:department_id]),
        StudentValid::Fields.room_num(info[:room_num], id: id)
      ])
      # ユーザー変更時のバリデーション, カラムごとのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    # 学生のパスワードを変更するときのバリデーション
    def self.update_passwd(id, info)
      result = { is_ok: false }

      # ユーザーのパスワード編集でのバリデーション
      record = StudentModel.get_By_id(id)
      field_result = format_field_results([
        UserValid::Procs.update_passwd(record.user_id, info)
      ])
      # ユーザーのパスワード編集でのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがいなかった場合, エラーメッセージを学生用に書き換える
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応する学生がいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    # 学生を削除するときのバリデーション
    def self.delete(id)
      result = { is_ok: false }

      # ユーザー削除のバリデーション
      record = StudentModel.get_By_id(id)
      field_result = format_field_results([
        UserValid::Procs.delete(record.user_id)
      ])
      # ユーザー削除のバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがいなかった場合, エラーメッセージを学生用に書き換える
        if result[:err][:type] == $err_types[:NOT_FOUND] && !result[:err][:details].nil?
          result[:err][:msg] = '学籍番号と対応する学生がいません' if result[:err][:details][:model] == 'user'
        end
        return result
      end
      result[:data] = field_result[:data]

      result[:is_ok] = true
      result
    end

    # 学生がログインするときのバリデーション
    def self.login(info)
      result = { is_ok: false }
      # 学籍番号が入力されていない場合はバリデーション失敗
      if info[:id] == ''
        result[:err] = err_obj(400, $err_types[:REQUIRE_FIELD], msg: '学籍番号は必須です')
        return result
      end

      # 学籍番号からメールアドレスを取得
      info[:email] = "#{info[:id]}@g.nagano-nct.ac.jp"
      # ユーザーがログインするときのバリデーション
      field_result = format_field_results([
        UserValid::Procs.login(info)
        ])
      # ユーザーがログインするときのバリデーションが失敗した場合
      unless field_result[:is_ok]
        result[:err] = field_result[:err]
        # ユーザーがいなかった場合, エラーメッセージを学生用に書き換える
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
