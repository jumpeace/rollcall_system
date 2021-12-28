require './helpers/active_record_init.rb'

class Building < ActiveRecord::Base
end

class BuildingModel
  def self.get_formatter(record, is_format)
    ng_result = is_format ? {} : nil

    return ng_result if record.nil?
    return record unless is_format

    { num: record.num }
  end

  def self.get_by_num(num, is_format: false)
    record = Building.find_by(num: num)
    BuildingModel.get_formatter(record, is_format)
  end

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
