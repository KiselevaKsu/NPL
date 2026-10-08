#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(strftime);

# проверяем аргументы
if (@ARGV < 1) {
    die "Usage: perl wordfreq.pl <input_file>\n";
}

my $input_file = $ARGV[0];

if (!-e $input_file) {
    die "Error: file '$input_file' not found\n";
}

# читаем файл
open(my $fh, '<', $input_file) or die "Cannot open '$input_file': $!\n";
my $text = do { local $/; <$fh> };
close($fh);

# разбиваем на слова: последовательности букв
my @words = lc($text) =~ /\b([a-zа-яё]+)\b/gi;

my $total = scalar @words;

# считаем частоту
my %freq;
$freq{$_}++ for @words;

# сортируем по убыванию частоты, при равенстве — по алфавиту
my @sorted = sort {
    $freq{$b} <=> $freq{$a} || $a cmp $b
} keys %freq;

# берём топ-20
my $top_n = 20;
my @top = @sorted[0 .. ($#sorted < $top_n - 1 ? $#sorted : $top_n - 1)];

# вывод в консоль
print "File: $input_file\n";
print "Total words: $total\n";
print "Top-$top_n:\n";

my $rank = 1;
for my $word (@top) {
    printf "  %2d. %-12s - %d\n", $rank, $word, $freq{$word};
    $rank++;
}

# дописываем отчёт в файл-журнал
my $log_file = "wordfreq.log";
open(my $log, '>>', $log_file) or die "Cannot open '$log_file': $!\n";

my $date = strftime("%Y-%m-%d %H:%M:%S", localtime);

print $log "===== $date =====\n";
print $log "File: $input_file\n";
print $log "Total words: $total\n";
print $log "Top-$top_n:\n";
$rank = 1;
for my $word (@top) {
    printf $log "  %2d. %-12s - %d\n", $rank, $word, $freq{$word};
    $rank++;
}
print $log "\n";
close($log);

print "\nReport appended to $log_file\n";