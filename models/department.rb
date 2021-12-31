require './helpers/active_record_init.rb'

class Department < ActiveRecord::Base
end

class DepartmentModel
  # 取得処理での返り値に利用
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    # レコードがない場合はないことを返す
    return ng_result if record.nil?
    # プログラム上で扱いやすい形式に変えないときはレコードのまま返す
    return record unless is_format

    # プログラム上で扱いやすい形式に変えるときは変えて返す
    { id: record.id, name: record.name, omit_name: record.omit_name }
  end

  # 学科の一覧を取得する
  def self.gets_all(is_format: false)
    result = {
      department_count: 0,
      departments: []
    }

    Department.all.each do |record|
      result[:departments].push(DepartmentModel.get_formatter(record, is_format))
    end

    result[:department_count] = result[:departments].length
    result
  end

  # IDによって学科を取得する
  def self.get_by_id(id, is_format: false)
    record = Department.find_by(id: id)
    DepartmentModel.get_formatter(record, is_format)
  end
end
