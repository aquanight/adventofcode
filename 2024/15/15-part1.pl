#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $xw = 0;
my $yw = 0;

my %walls;
my %boxes;
my $robot;

while (<>) {
	chomp;
	last if /^\s*$/;
	$xw = length if $xw < length;
	pos() = 0;
	while (/#/g) {
		my $x = $-[0];
		$walls{"$x,$yw"} = 1;
	}
	pos() = 0;
	while (/O/g) {
		my $x = $-[0];
		$boxes{"$x,$yw"} = 1;
	}
	pos() = 0;
	if (/@/g) {
		my $x = $-[0];
		$robot = [ $x, $yw ];
	}
	++$yw;
}

my @moves;

my %dir = (
	'>' => [1, 0],
	'<' => [-1, 0],
	'v' => [0, 1],
	'^' => [0, -1],
);

while (<>) {
	chomp;
	MOVE: for my $move (split //) {
		say STDERR "Step: $move";
		my (\$dx, \$dy) = \($dir{$move}->@*);
		
		my @moveboxes;
		my (\$rx, \$ry) = \($robot->@[0, 1]);
		my $nx = $rx + $dx;
		my $ny = $ry + $dy;
		while (1) {
			say STDERR "> Checking $nx, $ny";
			if ($walls{"$nx,$ny"}) {
				say STDERR "\t Hit wall";
				next MOVE;
			}
			elsif ($boxes{"$nx,$ny"}) {
				push @moveboxes, [ $nx, $ny ];
				$nx += $dx;
				$ny += $dy;
			}
			else {
				last;
			}
		}
		# Move the boxes
		for my $box (@moveboxes) {
			my ($bx, $by) = @$box;
			$boxes{"$bx,$by"}--;
			$bx += $dx;
			$by += $dy;
			$boxes{"$bx,$by"}++;
		}
		# Now move the robot
		$rx += $dx;
		$ry += $dy;
	}
}

my $score = 0;

for my $box (sort keys %boxes) {
	next unless $boxes{$box};
	my ($x, $y) = split /,/, $box;
	say STDERR "Box at $x,$y";
	$score += ($y * 100) + $x;
}

say $score;

