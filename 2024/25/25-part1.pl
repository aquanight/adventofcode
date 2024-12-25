#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @locks;

my @keys;

my $current;

my $yw = 0;

my $cury = 0;

my $xw = 0;

while (<>) {
	chomp;
	if (/^\s*$/) {
		$current = undef;
		$yw = $cury if $yw < $cury;
	}
	elsif (defined $current) {
		++$cury;
		$xw == length or die;
		my @pts = split //;
		for my $pt (keys @pts) {
			next unless $pts[$pt] eq '#';
			$current->[$pt]++;
		}
	}
	else {
		$cury = 0;
		$xw = length if $xw < length;
		if (/^#+$/) {
			$current = [ (0) x length ];
			push @locks, $current;
		}
		elsif (/^\.+$/) {
			$current = [ (-1) x length ];
			push @keys, $current;
		}
		else { die "[$_]"; }
	}
}

say STDERR "Master height: $yw";

say STDERR "Locks:";
for my $l (@locks) { say STDERR "@$l" }

say STDERR "Keys:";
for my $k (@keys) { say STDERR "@$k" }

my $ct = 0;

use List::Util ();

for my $l (@locks) {
	for my $k (@keys) {
		next unless List::Util::all { $l->[$_] + $k->[$_] < $yw } 0 .. ($xw - 1);
		say STDERR "Match: @$l / @$k";
		++$ct;
	}
}

say $ct;
