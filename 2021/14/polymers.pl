#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $current = <> // die "Missing input";

chomp $current;

my %rules;

while (<>) {
	chomp;
	next if /^\s*$/;
	if (my ($in, $out) = /^\s*([A-Z]{2})\s*-\>\s*([A-Z])\s*$/) {
		exists $rules{$in} and die "Duplicate rule";
		$rules{$in} = $out;
	}
}

sub step {
	for (my $ix = 0; $ix < length($current); ++$ix) {
		my $pair = substr($current, $ix, 2);
		my $result = $rules{$pair}//next;
		substr($current, ++$ix, 0) = $result;
	}
}

say STDERR "Starting: $current";

my $stepcount = 0;

while (++$stepcount <= 10) {
	step;
	say STDERR "Step $stepcount: $current";
}

my %nodes = map { $_ => 1 } split //, $current;

$nodes{$_} = () = ($current =~ /$_/g) for keys %nodes;

my @sorted = sort { $nodes{$a} <=> $nodes{$b} } keys %nodes;

my $score = $nodes{$sorted[-1]} - $nodes{$sorted[0]};

say "Value: $score";
