require './helpers/active_record_init.rb'

class Department < ActiveRecord::Base
end

class DepartmentModel
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    return ng_result if record.nil?
    return record unless is_format

    { id: record.id, name: record.name, omit_name: record.omit_name }
  end

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

  def self.get_by_id(id, is_format: false)
    record = Department.find_by(id: id)
    DepartmentModel.get_formatter(record, is_format)
  end
end
