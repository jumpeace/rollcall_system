# カラムのバリデーション結果群をフォーマットする
def format_field_results(valid_results)
  result = { is_ok: false }
  data = {}

  # カラムのバリデーションが１つでも失敗した場合はバリデーションが
  # 成功してないこととエラーメッセージを返す
  valid_results.each do |valid_result|
    unless valid_result[:is_ok]
      result[:err] = valid_result[:err]
      return result
    end

    # バリデーション処理で生成したデータを１つの変数にまとめる
    data = data.merge(valid_result[:data]) unless valid_result[:data].nil?
  end

  # すべてのバリデーションが成功した場合
  result[:data] = data
  result[:is_ok] = true
  result
end
