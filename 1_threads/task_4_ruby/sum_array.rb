# frozen_string_literal: true

require 'benchmark'

# сколько элементов и потоков
N = 10_000_000
T = 4

# генерируем массив случайных чисел
puts "Generating array of #{N} elements..."
array = Array.new(N) { rand(1..1000) }
puts "Array ready."

# последовательная сумма
seq_sum = 0
seq_time = Benchmark.realtime do
  array.each { |x| seq_sum += x }
end

puts "Sequential: sum = #{seq_sum}, time = #{(seq_time * 1000).round(3)} ms"

# параллельная сумма
par_sum = 0
mutex = Mutex.new

par_time = Benchmark.realtime do
  threads = []
  chunk = N / T

  T.times do |t|
    start_idx = t * chunk
    end_idx   = (t == T - 1) ? N : start_idx + chunk

    # копируем границы в локальные переменные для замыкания
    s = start_idx
    e = end_idx

    threads << Thread.new do
      local_sum = 0
      (s...e).each { |i| local_sum += array[i] }

      # складываем в общий результат под мьютексом
      mutex.synchronize { par_sum += local_sum }
    end
  end

  threads.each(&:join)
end

puts "Parallel  : sum = #{par_sum}, time = #{(par_time * 1000).round(3)} ms, threads = #{T}"
puts "Results match: #{seq_sum == par_sum ? 'yes' : 'NO'}"