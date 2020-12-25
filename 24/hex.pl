#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

# hex movement directions:

# All north/south movements must also include a half-integer east/west movement.

# The movement is expressed as (delta_x, delta_y)

my $steps = shift @ARGV; # 0 just does the initial read giving part 1 state

use constant dir_e => (1, 0);
use constant dir_ne => (0.5, 1);
use constant dir_se => (0.5, -1);
use constant dir_w => (-1, 0);
use constant dir_nw => (-0.5, 1);
use constant dir_sw => (-0.5, -1);

my %tiles;

while (<>) {
	my ($x, $y) = (0, 0); # Reference tile
	chomp;
	while (/\G[ns]?[ew]/g) {
		my $direction = $&;
		my ($dx, $dy) = main->can("dir_$direction")->();
		$x += $dx;
		$y += $dy;
	}
	$tiles{"$x:$y"} = !($tiles{"$x:$y"});
}

my $count = grep { $_ } values %tiles;

sub neighbors {
	my ($x, $y) = @_;
	my @n;
	for my $dir (grep { /^dir_/ && main->can($_) } keys %::) {
		my ($dx, $dy) = main->can($dir)->();
		my $xp = $x + $dx;
		my $yp = $y + $dy;
		push @n, $xp, $yp;
	}
	return @n;
}

say "Initial black tiles: $count";

my $stepno = 1;

while ($stepno <= $steps) {
	# Things will only happen around the black tiles.
	my @flip;
	my @black = grep { $tiles{$_} } keys %tiles;
	my %white = map { $_ => 1 } grep { !$tiles{$_} } keys %tiles;
	for my $black (@black) {
		my $adjblk = 0;
		my ($x, $y) = split /:/, $black;
		my @n = neighbors $x, $y;
		my ($nx, $ny);
		while (($nx, $ny) = splice @n, 0, 2) {
			if($tiles{"$nx:$ny"}) {
				++$adjblk;
			}
			else {
				$white{"$nx:$ny"} = 1; # A neighbor white tile we'll need to check for flipping
			}
		}
		if ($adjblk == 0 || $adjblk > 2) {
			push @flip, $black;
		}
	}
	for my $white (keys %white) {
		my $adjblk = 0;
		my ($x, $y) = split /:/, $white;
		my @n = neighbors $x, $y;
		my ($nx, $ny);
		while (($nx, $ny) = splice @n, 0, 2) {
			if ($tiles{"$nx:$ny"}) {
				++$adjblk;
			}
		}
		if ($adjblk == 2) {
			push @flip, $white;
		}
	}
	for my $tile (@flip) {
		$tiles{$tile} = !$tiles{$tile};
	}

	$count = grep { $_ } values %tiles;

	say "Day $stepno: $count black tiles";
	++$stepno;
}
