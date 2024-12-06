#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $xw = 0;
my $yw = 0;
my @dirs = (
	[ 0, -1],
	[ 1,  0],
	[ 0,  1],
	[-1,  0],
);


sub guard_walk ($gx, $gy, $gd, @obs) {
	my %obs = map { $_ => 1 } @obs;

	unless (defined $gx && defined $gy && defined $gd) {
		die "Uh oh";
	}

	my %visit;

	while ($gx > 0 && $gx <= $xw && $gy > 0 && $gy <= $yw) {
		# If we've already gone this way, it's a loop.
		if ($visit{"$gx,$gy"}->[$gd]) {
			return (1, \%visit);
		}
		$visit{"$gx,$gy"}->[$gd] = 1;
		my $dir = $dirs[$gd];
		my $nx = $gx + $dir->[0];
		my $ny = $gy + $dir->[1];
		if ($obs{"$nx,$ny"}) {
			$gd = ($gd + 1) % @dirs;
		}
		else {
			($gx, $gy) = ($nx, $ny);
		}
	}

	# Walked out, not a loop, return the result.
	return (0, \%visit);
}


my @obs;

my $gx = undef;
my $gy = undef;
my $gd = undef;

while (<>) {
	chomp;
	/^[\.#\^]+$/ or die "Input error: $_";
	if ($xw < length) { $xw = length; }
	++$yw;
	while (/#/g) {
		my $key = sprintf "%d,%d", pos, $yw;
		push @obs, $key;
	}
	pos($_) = 0;
	if (/\^/) {
		$gx = $+[0];
		$gy = $yw;
		$gd = 0;
	}
}

# Get the baseline path:
my ($isloop, $visit) = guard_walk($gx, $gy, $gd, @obs);

my %try;

for my $pos (keys %$visit) {
	my ($px, $py) = split /,/, $pos;
	for my $pd (keys @dirs) {
		next unless $visit->{"$px,$py"}->[$pd];
		my $dir = $dirs[$pd];
		my ($dx, $dy) = @$dir;
		my $nx = $px + $dx;
		my $ny = $py + $dy;
		next if $nx == $gx && $ny == $gy;
		next if $nx < 1 || $ny < 1 || $nx > $xw || $ny > $yw;
		say STDERR "Candidate location: $nx, $ny";
		$try{"$nx,$ny"} = 1;
	}
}

my $count = 0;

for my $try (keys %try) {
	($isloop, $visit) = guard_walk($gx, $gy, $gd, @obs, $try);
	if ($isloop) {
		say STDERR "Loop found at $try";
		++$count;
	}
}

say $count;
