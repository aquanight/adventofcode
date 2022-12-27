#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %grid;

my $cur_x;
my $cur_y = 1;

my $dx = 1;
my $dy = 0;

sub coord ($key) {
	my ($x, $y) = $key =~ /^(\d+),(\d+)$/ or Carp::confess "bad key";
	return ($x, $y);
}

sub get_x_extents ($y) {
	my @pts = sort { $a <=> $b } grep { defined } map { my ($_x, $_y) = coord($_); $_y == $y ? $_x : undef } keys %grid;
	if (@pts) { return @pts[0, -1]; }
	else { return () }
}

sub get_y_extents ($x) {
	my @pts = sort { $a <=> $b } grep { defined } map { my ($_x, $_y) = coord($_); $_x == $x ? $_y : undef } keys %grid;
	if (@pts) { return @pts[0, -1]; }
	else { return () }
}

sub turn_right {
	($dx, $dy) = (-$dy, $dx);
}

sub turn_left {
	($dx, $dy) = ($dy, -$dx);
}

sub step ($n) {
	assert $n >= 0;
	while ($n-- > 0) {
		my $mvx = $cur_x + $dx;
		my $mvy = $cur_y + $dy;
		my $next = $grid{"$mvx,$mvy"};
		if (!defined $next) {
			# Need to do a wrapping.
			if ($dx) {
				say STDERR "Horizontal wrapping at $mvy";
				assert !$dy;
				my ($lo, $hi) = get_x_extents $mvy;
				my $len = ($hi - $lo + 1);
				$mvx = (($mvx - $lo) % $len) + $lo;
				$next = $grid{"$mvx,$mvy"};
				assert defined($next);
			}
			else {
				say STDERR "Vertical wrapping at $mvx";
				assert $dy;
				my ($lo, $hi) = get_y_extents $mvx;
				say STDERR "Extents are $lo, $hi";
				my $len = ($hi - $lo + 1);
				$mvy = (($mvy - $lo) % $len) + $lo;
				$next = $grid{"$mvx,$mvy"};
				assert defined($next);
			}
		}
		if ($next eq '#') {
			last;
		}
		else {
			($cur_x, $cur_y) = ($mvx, $mvy);
		}
	}
}

while (<>) {
	print STDERR $_;
	chomp;
	last unless length;
	/^[ .#]+$/ or die "Input error";
	my $y = $.;
	while (m/[.#]/g) {
		my $x = pos;
		my $chr = $&;
		$grid{"$x,$y"} = $chr;
	}
}

($cur_x) = get_x_extents(1);

assert defined $cur_x;

my @instr = split /([RL])/, scalar(<>);

while (@instr) {
	my $instr = shift(@instr);
	chomp($instr);
	if ($instr eq 'R') { turn_right; }
	elsif ($instr eq 'L') { turn_left; }
	else { step(0 + $instr); }
}

my %facekey = ("1,0" => 0, "0,1" => 1, "-1,0" => 2, "0,-1" => 3);

say STDERR "Final position: x=$cur_x, y=$cur_y, dx=$dx, dy=$dy";

my $score = (1000 * $cur_y) + (4 * $cur_x) + $facekey{"$dx,$dy"};

say $score;
