#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $template = <> // die "Missing input";

chomp $template;

my %rules;

while (<>) {
	chomp;
	next if /^\s*$/;
	if (my ($in, $out) = /^\s*([A-Z]{2})\s*-\>\s*([A-Z])\s*$/) {
		exists $rules{$in} and die "Duplicate rule";
		$rules{$in} = $out;
	}
}

my %pairs;

my %nodecount;

$pairs{"$1$2"}++ while $template =~ m/(.)(?=(.))/g;

sub step {
	%nodecount = (substr($template, 0, 1) => 1);
	my %next;
	while (my ($pair, $count) = each %pairs) {
		my ($l, $r) = split //, $pair;
		my $in = $rules{$pair};
		if (defined $in) {
			$next{"$l$in"} += $count;
			$next{"$in$r"} += $count;
			$nodecount{$in} += $count;
			$nodecount{$r} += $count;
		}
		else {
			$next{"$l$r"} += $count;
			$nodecount{$r} += $count;
		}
	}
	%pairs = %next;
}

say STDERR "Starting: " . join " ", %pairs;;

my $stepcount = 0;

while (++$stepcount <= 40) {
	step;
	say STDERR "Step $stepcount: " . join " ", %pairs;;
}

my @sorted = sort { $nodecount{$a} <=> $nodecount{$b} } keys %nodecount;

my $score = $nodecount{$sorted[-1]} - $nodecount{$sorted[0]};

say "Value: $score";
