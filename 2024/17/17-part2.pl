#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use integer;

my $initB = 0;
my $initC = 0;

my $A;
my $B;
my $C;
my $PC;

sub combo ($op) {
	return (0, 1, 2, 3, $A, $B, $C, undef)[$op];
}

sub adv ($op) {
	my $val = 2 ** combo($op);
	$A = int($A / $val);
}

sub bxl ($op) {
	$B ^= $op;
}

sub bst ($op) {
	$B = combo($op) % 8;
}

sub jnz ($op) {
	if ($A) {
		$PC = $op;
	}
}

sub bxc ($op) {
	$B ^= $C;
}

my @out;
sub out ($op) {
	my $val = combo($op) % 8;
	push @out, $val;
}

sub bdv ($op) {
	my $val = 2 ** combo($op);
	$B = int($A / $val);
}

sub cdv ($op) {
	my $val = 2 ** combo($op);
	$C = int($A / $val);
}

my @ops = (\&adv, \&bxl, \&bst, \&jnz, \&bxc, \&out, \&bdv, \&cdv);

my @prog;

while (<>) {
	chomp;
	next if /^$/;
	if (my ($reg, $val) = /^Register ([ABC]): (\d+)/) {
		if ($reg eq 'B') { $initB = $val; }
		if ($reg eq 'C') { $initC = $val; }
	}
	elsif (my ($ops) = /^Program: ([\d,]+)/) {
		@prog = split /,/, $ops;
	}
}

sub run {
	@out = ();
	$PC = 0;
	while ($PC < @prog) {
		my $opc = $prog[$PC++];
		my $opv = $prog[$PC++];
		$ops[$opc]->($opv);
	}

}

my @cand;
# Find the first 3 bits of A:
for my $bits ( 0 .. 7 ) {
	say STDERR "Trying $bits";
	($A, $B, $C) = ($bits, $initB, $initC);
	run;
	say STDERR "> Result @out";
	if ($out[0] == $prog[-1]) {
		push @cand, $bits;
	}
}

say STDERR "Initial candidates: @cand";

# Now the rest of A
for my $len ( 2 .. @prog ) {
	my @newcand;
	for my $cand (@cand) {
		BIT: for my $bits ( 0 .. 7 ) {
			my $try = ($cand * 8) + $bits;
			say STDERR "Trying $try";
			$A = $try;
			$B = $initB;
			$C = $initC;
			run;
			say STDERR "> Result @out";
			next if @out < $len;
			for my $ix ( 0 .. ($len - 1) ) {
				next BIT unless $out[$ix] == $prog[(@prog - $len) + $ix];
			}
			push @newcand, $try;
		}
	}
	\@cand = \@newcand;
	say STDERR "Step $len candidates: @cand";
	die unless @cand;
}

my ($result) = sort {$a <=> $b} @cand;

say $result;
