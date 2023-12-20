#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %rules;

while (<>) {
	chomp;
	length or last;
	my ($name, $rule) = /^(\w+?)\{(.+)\}$/;
	defined $name or die "Input error";
	my @rule = split /,/, $rule;
	my $ruleproc = q'sub ($X, $M, $A, $S) {';
	$ruleproc .= "\n";
	while (defined(my $r = shift @rule)) {
		if (my ($var, $cmp, $val, $target) = $r =~ m/^([xmas])([\<\>])(\d+):(\w+)$/) {
			$ruleproc .= sprintf "\$%s %s %d and return q[%s];\n", uc($var), $cmp, $val, $target;
		}
		else {
			$ruleproc .= "return q[$r];\n";
		}
	}
	$ruleproc .= "}\n";
	say STDERR "Prepared rule for flow $name:";
	print STDERR $ruleproc;
	my $rulesub = eval "$ruleproc";
	use B::Deparse ();
	defined $rulesub or die $@;
	$rules{$name} = $rulesub;
}

my $accept = 0;

while (<>) {
	my ($values) = /^\{(.+)\}$/;
	defined $values or die "Input error";
	my ($X, $M, $A, $S);
	for my $v (split /,/, $values) {
		my ($rate, $rating) = $v =~ /([xmas}])=(\d+)/;
		defined $rate or die "Uh oh";
		if ($rate eq 'x') { $X = $rating; }
		elsif ($rate eq 'm') { $M = $rating; }
		elsif ($rate eq 'a') { $A = $rating; }
		elsif ($rate eq 's') { $S = $rating; }
	}
	defined($X) && defined($M) && defined($A) && defined($S) or die "Problem";
	my $flow = "in";
	until ($flow eq "A" || $flow eq "R") {
		$flow = $rules{$flow}->($X, $M, $A, $S);
	}
	if ($flow eq 'A') {
		$accept += ($X + $M + $A + $S);
	}
}

say $accept;
