# 任意の自然数から下限の桁数と取得する桁数を指定して取得する
def get_num_by_digit(src, lower, count = 1)
  src.to_s.split('')[lower..(lower + count - 1)].join('').to_i
end
