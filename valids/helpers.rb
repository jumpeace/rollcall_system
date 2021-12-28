def exec_field_procs(valid_results)
  result = { is_ok: false }
  data = {}

  valid_results.each do |valid_result|
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    data = data.merge(valid_result[:data]) unless valid_result[:data].nil?
  end

  result[:data] = data
  result[:is_ok] = true
  result
end
