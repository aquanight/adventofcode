#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @seeds;

my %seed;
my %soil;
my %fert;
my %water;
my %light;
my %temp;
my %humid;

my $current_map = undef;

while (<>) {
	if (/^\s*$/) {
		$current_map = undef;
	}
	elsif (my ($seeds) = /^seeds:\s+([\d\s]+)$/) {
		push @seeds, split /\s+/, $seeds;
	}
	elsif (/^seed-to-soil map:$/) { $current_map = \%seed; }
	elsif (/^soil-to-fertilizer map:$/) { $current_map = \%soil; }
	elsif (/^fertilizer-to-water map:$/) { $current_map = \%fert; }
	elsif (/^water-to-light map:$/) { $current_map = \%water; }
	elsif (/^light-to-temperature map:$/) { $current_map = \%light; }
	elsif (/^temperature-to-humidity map:$/) { $current_map = \%temp; }
	elsif (/^humidity-to-location map:$/) { $current_map = \%humid; }
	elsif (my ($dstart, $sstart, $len) = /^(\d+) (\d+) (\d+)$/) {
		ref $current_map or die "Bummer";
		$current_map->{$sstart} = [$dstart, $len];
	}
	else { die "Bad line '$_'"; }
}

my @cur = @seeds;
for my $map (\%seed, \%soil, \%fert, \%water, \%light, \%temp, \%humid) {
	for my $cur (@cur) {
		for my $rsrc (keys %$map) {
			next unless $cur >= $rsrc;
			my ($rdst, $rlen) = $map->{$rsrc}->@*;
			next unless $cur < ($rsrc + $rlen);
			my $dest = $rdst + ($cur - $rsrc);
			$cur = $dest;
			last;
		}
	}
}

@cur = sort { $a <=> $b } @cur;

say $cur[0];
