#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @packets = ([[2]], [[6]]);

my $two = 0;
my $six = 1;

my $score = 0;

sub compare_lists ($l, $r) {
	ref($l)||Carp::confess;
	ref($r)||Carp::confess;
	my @left = @$l;
	my @right = @$r;
	while (@left || @right) {
		my $lv = shift @left;
		my $rv = shift @right;
		if (defined($lv) != defined($rv)) {
			return defined($lv) - defined($rv);
		}
		if (!defined($lv)) {
			assert !defined($rv);
			next;
		}
		if (!ref($lv) != !ref($rv)) {
			if (ref($lv)) { $rv = [ $rv ]; }
			else { $lv = [ $lv ]; }
		}
		if (ref($lv)) {
			assert ref($rv);
			if ($#$lv < $#$rv) {
				$#$lv = $#$rv;
			}
			elsif ($#$lv > $#$rv) {
				$#$rv = $#$lv;
			}
			unshift @left, @$lv;
			unshift @right, @$rv;
			next;
		}
		if ($lv < $rv) {
			return -1;
		}
		elsif ($lv > $rv) {
			return 1;
		}
	}
	return 0;
}



while (<>) {
	chomp;
	next if /^\s*$/;
	/^[\[,\d\]]+$/ or die "Input error";
	my $pkt = eval "$_"//die "Problem with input <$_>: $@";
	my ($lo, $hi) = (0, scalar @packets);
	while ($lo < $hi) {
		my $cur = int(($hi - $lo) / 2 + $lo);
		my $cmp = compare_lists($pkt, $packets[$cur]//die "WTF is wrong with <$cur>");
		if ($cmp > 0) {
			$lo = $cur + 1;
		}
		else {
			$hi = $cur;
		}
	}
	splice @packets, $lo, 0, $pkt;
	# Update these indices
	if ($lo <= $two) {
		++$two;
	}
	if ($lo <= $six) {
		++$six;
	}
}

$score = ($two + 1) * ($six + 1);

say $score;
