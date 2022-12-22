#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @grid;

my $width = undef;

my ($end_x, $end_y);

my @starts;

my %map;

@map{'a' .. 'z'} = 1 .. 26;

while (<>) {
	chomp;
	$width//= length;
	$width == length() or die "Irregular grid";
	if (/[aS]/) {
		push @starts, $-[0], scalar(@grid);
		substr($_, $-[0], 1) = 'a';
	}
	if (/E/) {
		$end_x = $-[0];
		$end_y = @grid;
		substr($_, $-[0], 1) = 'z';
	}
	push @grid, [ @map{split //} ];
}

my @path;

my @fill_set = (0, $end_x, $end_y);

while (@fill_set > 0) {
	my ($len, $x, $y) = splice @fill_set, 0, 3;
	defined $path[$y][$x] and next;
	$path[$y][$x] = $len;
	my $limit = $grid[$y][$x] - 1;
	if ($y > 0 && $grid[$y - 1][$x] >= $limit) {
		push @fill_set, ($len+1, $x, $y - 1);
	}
	if ($x > 0 && $grid[$y][$x - 1] >= $limit) {
		push @fill_set, ($len+1, $x - 1, $y);
	}
	if ($y < $#grid && $grid[$y + 1][$x] >= $limit) {
		push @fill_set, ($len+1, $x, $y + 1);
	}
	if ($x < ($width - 1) && $grid[$y][$x + 1] >= $limit) {
		push @fill_set, ($len+1, $x + 1, $y);
	}
}

my $score;

while (@starts) {
	my ($x, $y) = splice(@starts, 0, 2);
	my $len = $path[$y][$x];
	$score = defined($score) && $score < $len ? $score : $len;
}

say $score;
