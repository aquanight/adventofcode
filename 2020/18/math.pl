#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

sub math {
	my $in = shift;
	#say "Entering $in";
	my $og = $in;

	$in =~ s/\s+//g; # Strip all whitespace

	my $value;

	# If we are starting with a simple number, then good, use that:
	if ($in =~ m/^\d+/) {
		$value = 0 + $&;
		$in = $';
	}
	elsif ($in =~ /^(\(((?:(?>[^()]+)|(?1))*)\))/) {
		my $expr = $2;
		$in = $';
		#say "Subexpr: $expr, Remain: $in";
		$value = math($2);
	}

	while ($in =~ /^[+*]/) {
		my $op = $&;
		$in = $';
		my $other;
		if ($in =~ m/^\d+/) {
			$other = 0 + $&;
			$in = $';
		}
		elsif ($in =~ /^(\(((?:(?>[^()]+)|(?1))*)\))/) {
			my $expr = $2;
			$in = $';
			#say "Subexpr: $expr, Remain: $in";
			$other = math($2);
		}
		if ($op eq '+') { $value += $other; }
		if ($op eq '*') { $value *= $other; }
	}

	#say "$og = $value";

	return $value;
}

sub math2 {
	my $in = shift;
	# Multiplication is commutative so it doesn't matter if we evaluate it right-to-left instead of left-to-right.
	my $og = $in;

	$in =~ s/\s+//g; # Strip all whitespace

	my $value;

	# If we are starting with a simple number, then good, use that:
	if ($in =~ m/^\d+/) {
		$value = 0 + $&;
		$in = $';
	}
	elsif ($in =~ /^(\(((?:(?>[^()]+)|(?1))*)\))/) {
		my $expr = $2;
		$in = $';
		#say "Subexpr: $expr, Remain: $in";
		$value = math2($2);
	}

	while ($in =~ /^[+*]/) {
		my $op = $&;
		$in = $';
		my $other;
		if ($op eq '*') {
			$other = math2($in);
			return $value * $other;
		}
		elsif ($op eq '+') {
			if ($in =~ m/^\d+/) {
				$other = 0 + $&;
				$in = $';
			}
			elsif ($in =~ /^(\(((?:(?>[^()]+)|(?1))*)\))/) {
				my $expr = $2;
				$in = $';
				#say "Subexpr: $expr, Remain: $in";
				$other = math2($2);
			}
			$value += $other;
		}
	}

	#say "$og = $value";

	return $value;
}

my $sum = 0;
my $sum2 = 0;

while (<>) {
	chomp;
	my $val = math $_;
	my $val2 = math2 $_;
	say "$_ = $val";
	say "$_ =2 $val2";
	$sum += $val;
	$sum2 += $val2;
}

say "Total: $sum";
say "Total2: $sum2";
