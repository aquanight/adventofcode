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
	my @step;
	say STDERR "--";
	while (@cur) {
		my $cur = shift @cur;
		my $curlen = shift @cur;
		say STDERR "Range: $cur .. $curlen";
		for my $rsrc (keys %$map) {
			next if $rsrc >= $cur + $curlen;
			my ($rdst, $rlen) = $map->{$rsrc}->@*;
			next if $rsrc + $rlen <= $cur;
			if ($rsrc > $cur) {
				unshift @cur, $rsrc, $curlen - ($rsrc - $cur);
				$curlen = ($rsrc - $cur);
			}
			else {
				my $offset = $cur - $rsrc;
				my $max = $rlen - $offset;
				my $dstart = $rdst + $offset;
				if ($curlen > $max) {
					my $stop = $cur + $max;
					unshift @cur, $stop, ($curlen - $max);
					$curlen = $max;
				}
				push @step, $dstart, $curlen;
				$curlen = 0;
			}
		}
		if ($curlen > 0) {
			push @step, $cur, $curlen;
		}
	}
	@cur = @step;
}

say STDERR join " : ", @cur;

my $lowest;
for (my $ix = 0; $ix < @cur; $ix += 2) {
	my $v = $cur[$ix];
	unless (($lowest//$v) < $v) {
		$lowest = $v;
	}
}

say $lowest;
