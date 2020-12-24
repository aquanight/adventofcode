#!/usr/bin/perl
use v5.30;
use warnings;
use warnings FATAL=>'uninitialized';

use List::Util ();

my @input;

my @set;

my %set;

use constant PREAMBLE => shift(@ARGV);

sub crack {
	my $invalid = shift//die "WTF";
	my @subseq;
	my $next = 0;

	while (1) {
		my $sum = List::Util::sum(@subseq)//0;
		if ($sum == $invalid) {
			last;
		}
		elsif ($sum < $invalid) {
			push @subseq, $input[$next++];
		}
		elsif ($sum > $invalid) {
			shift @subseq;
		}
	}

	say "Found sequence @subseq";

	my $break = List::Util::min(@subseq) + List::Util::max(@subseq);
	say "Cracked: $break";
}

INPUT: while (<>) {
	chomp;
	$_ = 0+$_;
	if (scalar @set < PREAMBLE) {
		push @input, $_;
		push @set, $_;
		$set{$_} = 1;
		next INPUT;
	}
	my $ok = 0;
	for my $current (@set) {
		my $other = $_ - $current;
		exists $set{$other} and do {
			$ok = 1;
			last;
		}
	}
	unless ($ok) {
		say "Found invalid entry: $_";
		crack $_;
	}
	my $gone = shift @set;
	delete $set{$gone};
	push @input, $_;
	push @set, $_;
	$set{$_} = 1;
}
