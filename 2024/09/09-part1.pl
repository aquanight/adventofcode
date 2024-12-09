#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

my $map = <>;

chomp $map;

my @counts = split //, $map;

my @layout;

my $sz = List::Util::sum @counts;

$#layout = $sz - 1;

my $lix = 0;

my $id = 0;

while (@counts) {
	my $file = shift @counts;
	my $free = shift(@counts) // 0;

	while ($file > 0) {
		$layout[$lix++] = $id;
		--$file;
	}

	$lix += $free;
	++$id;
}

my $free = 0;
my $lastfile = $#layout;

while (1) {
	++$free while defined $layout[$free];
	--$lastfile until defined $layout[$lastfile];
	$free < $lastfile or last;

	$layout[$free] = $layout[$lastfile];
	$layout[$lastfile] = undef;
}

my $chk = List::Util::sum map { $_ * ($layout[$_] // 0) } keys @layout;

say $chk;
