#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;
my $width;

while (<>) {
	chomp;
	/^[\.\#O]+$/ or die "Input error";
	push @map, $_;
	$width //= length;
}

sub roll ($str) {
	while ($str =~ s/(\.+)O/O$1/) {
	}
	return $str;
}

# Spin Cycle!
sub tilt_north {
	for my $x (0 .. ($width - 1)) {
		my $inp = join "", map { substr($_, $x, 1) } @map;
		my @rolled = split //, roll($inp);
		die unless length($inp) == @rolled;
		substr($map[$_], $x, 1, $rolled[$_]) for 0 .. $#map;
	}
}

sub tilt_west {
	for my $l (@map) {
		$l = roll($l);
	}
}

sub tilt_south {
	for my $x (0 .. ($width - 1)) {
		my $inp = join "", map { substr($_, $x, 1) } @map;
		my @rolled = reverse(split //, roll(scalar reverse $inp));
		die unless length($inp) == @rolled;
		substr($map[$_], $x, 1, $rolled[$_]) for 0 .. $#map;
	}
}

sub tilt_east {
	for my $l (@map) {
		$l = reverse roll(scalar reverse $l);
	}
}

# Tilting
my $load = 0;

say STDERR for @map;

my %seen;

use constant STEPS => 1000000000;

for (my $step = 1; $step <= STEPS; ++$step) {
	tilt_north;
	tilt_west;
	tilt_south;
	tilt_east;
	my $key = join "\n", @map;
	if (defined $seen{$key}) {
		my $looplen = $step - $seen{$key};
		print STDERR "Loop found from $seen{$key} to $step (length $looplen)";
		# fast forward to the final loop
		my $offset = $step % $looplen;
		my $lastloop = STEPS;
		until (($lastloop % $looplen) == $offset) {
			--$lastloop;
		}
		say STDERR " -- fast-forward to $lastloop";
		# Clear out the loop defs
		$step = $lastloop;
		undef %seen;
	}
	else {
		$seen{$key} = $step;
	}
}

say STDERR "--";

say STDERR for @map;

for my $y (0 .. $#map) {
	my $row = @map - $y;
	$load += $row * (() = $map[$y] =~ /O/g);
}

say $load;
