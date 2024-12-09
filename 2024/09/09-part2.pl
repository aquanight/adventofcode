#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

my $map = <>;

chomp $map;

my @counts = split //, $map;

my @files;
my @free;

my $id = 0;

my $pos = 0;

while (@counts) {
	my $file = shift @counts;
	my $free = shift(@counts) // 0;

	$files[$id++] = { size => $file, pos => $pos };
	$pos += $file;
	push @free, { size => $free, pos => $pos };
	$pos += $free;
}

while ($id > 0) {
	--$id;
	my $file = $files[$id];
	my @spots = sort { $a->{pos} <=> $b->{pos} } grep { $_->{pos} < $file->{pos} && $_->{size} >= $file->{size} } @free;
	next if @spots < 1;
	my $spot = shift @spots;
	$file->{pos} = $spot->{pos};
	$spot->{pos} += $file->{size};
	$spot->{size} -= $file->{size};
	# Since we're doing one pass, we can ignore the newly freed up space where $file was.
}

my $chk = 0;

for $id (keys @files) {
	my $file = $files[$id];
	my ($pos, $size) = $file->@{qw/pos size/};
	my $t = (($pos + $size) * ($pos + $size - 1) / 2) - ($pos * ($pos - 1)) / 2;
	$chk += $t * $id;
}

say $chk;
