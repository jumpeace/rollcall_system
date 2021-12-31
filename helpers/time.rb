class MyTime
  # 閏年であるか判定
  def self.leap_year?(year)
    (year % 4).zero? && (year % 100 != 0 || (year % 400).zero? )
  end

  # 月が正しいか判定
  def self.correct_month?(month)
    month >= 1 && month <= 12
  end

  # 任意の年月の日数を取得する
  def self.get_mday_num(year, month)
    return nil  unless correct_month?(month)
    return leap_year?(year) ? 29 : 28 if month == 2

    [31, nil, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1]
  end

  # 正確な時間か判定
  def self.correct_time?(year, month, date: nil)
    return false unless correct_month?(month)

    unless date.nil?
      return false unless date >= 1 && date <= get_mday_num(year, month)
    end

    true
  end

  # 任意の年月日を現在と比べて過去か現在か将来か判定する
  def self.compare_day(year, month, date)
    now = Time.now
    return year > now.year ? 'future' : 'past' unless year == now.year
    return month > now.month ? 'future' : 'past' unless month == now.month
    return date > now.day ? 'future' : 'past' unless date == now.day

    'now'
  end

  # 任意の時間を年月日を考えずに現在と比べて過去か現在か将来か判定する
  def self.compare_time(hour, minute)
    now = Time.now
    return hour > now.hour ? 'future' : 'past' unless hour == now.hour
    return minute > now.min ? 'future' : 'past' unless minute == now.min

    'now'
  end

  # 時間を数値から文字に変換
  def self.str(time)
    formatted = {}

    formatted[:year] = time[:year].to_s.rjust(4) unless time[:year].nil?
    formatted[:month] = time[:month].to_s.rjust(2) unless time[:month].nil?
    formatted[:date] = time[:date].to_s.rjust(2) unless time[:date].nil?
    formatted[:hour] = time[:hour].to_s.rjust(2) unless time[:hour].nil?
    formatted[:minute] = time[:minute].to_s.rjust(2, '0') unless time[:minute].nil?

    formatted
  end
end
