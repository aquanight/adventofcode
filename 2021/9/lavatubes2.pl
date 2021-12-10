#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use List::Util ();

my @hmap;

while (<>) {
	chomp;
	/^\d+$/ or die "Invalid input";
	push @hmap, $_;
}

sub valid ($x, $y) {
	if ($y < 0 || $y > $#hmap) { return; }
	my $r = $hmap[$y];
	if ($x < 0 || $x >= length($r)) { return; }
	return @_;
}

sub height ($x, $y) {
	if ($y < 0 || $y > $#hmap) { return; }
	my $r = $hmap[$y];
	if ($x < 0 || $x >= length($r)) { return; }
	0 + substr($r, $x, 1);
}

sub neighbors ($x, $y) {
	# height returns empty list if we go off the edge.
	my @r = (height($x - 1, $y), height($x + 1, $y), height($x, $y - 1), height($x, $y + 1));
	return @r;
}

sub valid_neighbors ($x, $y) {
	my @r = (valid($x - 1, $y), valid($x + 1, $y), valid($x, $y - 1), valid($x, $y + 1));
	return @r;
}

sub is_low ($x, $y) {
	my $h = height($x, $y);
	my @n = neighbors($x, $y);
	return List::Util::all { $h < $_ } @n;
}

sub basin_size ($x, $y) {
	my @n = ($x, $y);
	my %seen;
	my $ix = 0;
	ITEM: while ($ix < @n) {
		my $cx = $n[$ix++];
		my $cy = $n[$ix++];
		$_ = $_ ? next ITEM : 1 for $seen{"$cx,$cy"};
		my $cur = height($cx, $cy);
		say STDERR "At ($cx, $cy) : $cur";
		next if $cur > 7;
		my @next = valid_neighbors($cx, $cy);
		@next = List::Util::pairgrep { height($a, $b) < 9 } @next;
		push @n, @next;
	}
	return scalar keys %seen;
}

my @basins;

my $risk = 0;

for my $y (0 .. $#hmap) {
	for my $x (0 .. length($hmap[$y]) - 1) {
		if (is_low($x, $y)) {
			my $h = height($x, $y);
			my $basin = basin_size($x, $y);
			push @basins, { size => $basin, x => $x, y => $y };
			say STDERR "Low point at ($x, $y) : $h -- Basin $basin";
			$risk += (1 + $h);
		}
	}
}

@basins = sort { $b->{size} <=> $a->{size} } @basins;

say "Top 3 basins:";
for my $b (@basins[0, 1, 2]) {
	printf STDERR "Size %d at %d, %d\n", $b->@{qw/size x y/};
}

my $prod = $basins[0]->{size} * $basins[1]->{size} * $basins[2]->{size};

say "Total risk value is $risk";

say "Product $prod";
