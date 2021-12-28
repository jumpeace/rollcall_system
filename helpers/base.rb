def get_num_by_digit(src, lower, count = 1)
  src.to_s.split('')[lower..(lower + count - 1)].join('').to_i
end
