#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $xw = 0;
my $yw = 0;

my %obs;

my @dirs = (
	[ 0, -1],
	[ 1,  0],
	[ 0,  1],
	[-1,  0],
);

my $gx = undef;
my $gy = undef;
my $gd = undef;

while (<>) {
	print STDERR $_;
	chomp;
	/^[\.#\^]+$/ or die "Input error: $_";
	if ($xw < length) { $xw = length; }
	++$yw;
	while (/#/g) {
		my $key = sprintf "%d,%d", pos, $yw;
		$obs{$key} = 1;
	}
	pos($_) = 0;
	if (/\^/) {
		$gx = $+[0];
		$gy = $yw;
		$gd = 0;
	}
}

unless (defined $gx && defined $gy && defined $gd) {
	die "Uh oh";
}

say STDERR "Start at $gx,$gy, bounds at $xw, $yw";

my %visit;

while ($gx > 0 && $gx <= $xw && $gy > 0 && $gy <= $yw) {
	$visit{"$gx,$gy"} = 1;
	my $dir = $dirs[$gd];
	my $nx = $gx + $dir->[0];
	my $ny = $gy + $dir->[1];
	if ($obs{"$nx,$ny"}) {
		$gd = ($gd + 1) % @dirs;
	}
	else {
		($gx, $gy) = ($nx, $ny);
	}
	say STDERR "Now at $gx,$gy, Moving $dirs[$gd]->@*";
}

say scalar(keys %visit);
