#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use integer;

my $A;
my $B;
my $C;

my $PC = 0;

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
		if ($reg eq 'A') { $A = $val; }
		if ($reg eq 'B') { $B = $val; }
		if ($reg eq 'C') { $C = $val; }
	}
	elsif (my ($ops) = /^Program: ([\d,]+)/) {
		@prog = split /,/, $ops;
	}
}

while ($PC < @prog) {
	my $opc = $prog[$PC++];
	my $opv = $prog[$PC++];
	$ops[$opc]->($opv);
}

say join ",", @out;
