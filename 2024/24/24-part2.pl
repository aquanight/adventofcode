#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %input;

my %ops;

while (<>) {
	if (my ($line, $val) = /^(\w+): ([01])$/) {
		$input{$line} = $val;
	}
	elsif (my ($i1, $op, $i2, $out) = /^(\w+) (AND|OR|XOR) (\w+) -> (\w+)$/) {
		$ops{$out} = [ $op, $i1, $i2 ];
	}
	elsif (/^$/) { }
	else { die; }
}

sub run {
	my %lines = %input;
	my %pending = %ops;
	while (%pending) {
		for my $p (keys %pending) {
			my ($op, $i1, $i2) = $pending{$p}->@*;
			defined($lines{$i1}) or next;
			defined($lines{$i2}) or next;
			my $l1 = $lines{$i1};
			my $l2 = $lines{$i2};
			delete $pending{$p};
			if ($op eq "AND") { $lines{$p} = $l1 && !!$l2; }
			elsif ($op eq "OR") { $lines{$p} = !!$l1 || !!$l2; }
			elsif ($op eq "XOR") { $lines{$p} = (!$l1) != !($l2); }
		}
	}
	%lines;
}

my ($last) = sort { $b cmp $a } (grep /^z/, keys %input, keys %ops);

my %bad;

for my $out (keys %ops) {
	my ($op, $i1, $i2) = $ops{$out}->@*;
	if ($out =~ /^z/) {
		unless ($out eq $last || $op eq "XOR") {
			$bad{$out} = 1;
		}
	}
	else {
		unless ($op eq "AND" || $op eq "OR" || ($i1 =~ /^x/ && $i2 =~ /^y/) || ($i1 =~ /^y/ && $i2 =~ /^x/)) {
			$bad{$out} = 2;
		}
	}
}

say STDERR "Bad so far: " . join ",", %bad;

for my $bad (grep { $bad{$_} == 2 } keys %bad) {
	say STDERR "Suspect $bad [ $ops{$bad}->@* ]";
	my ($step) = sort { $b cmp $a } grep { $ops{$_}->[1] eq $bad || $ops{$_}->[2] eq $bad } keys %ops;
	until ($step =~ /^z/) {
		say STDERR "> Step $step [ $ops{$step}->@* ]";
		my @found = sort { $b cmp $a } grep { $ops{$_}->[1] eq $step || $ops{$_}->[2] eq $step } keys %ops;
		say STDERR "Found @found";
		($step) = @found;
	}
	say STDERR "Leads to $step [ $ops{$step}->@* ]";
	my ($bit) = $step =~ /^z(\d+)/;
	--$bit;
	my $other = sprintf "z%02d", $bit;
	die unless $bad{$other} == 1;
	say "Pairs it with $other";
	$bad{$bad} = $other;
	$bad{$other} = $bad;
	@ops{$bad, $other} = @ops{$other, $bad};
}

my %out = run;

my $xbit = join "", map { $out{$_} ? 1 : 0 } sort { $b cmp $a } grep /^x/, keys %out;
my $ybit = join "", map { $out{$_} ? 1 : 0 } sort { $b cmp $a } grep /^y/, keys %out;
my $zbit = join "", map { $out{$_} ? 1 : 0 } sort { $b cmp $a } grep /^z/, keys %out;

my($x, $y, $z);
{
	use bigint;
	$x = oct("0b$xbit");
	$y = oct("0b$ybit");
	$z = oct("0b$zbit");
}

my $wrong = ($x + $y) ^ $z;

printf STDERR "%b\n", $wrong;

my ($zeros) = sprintf("%b", $wrong) =~ /1(0+)$/;

my $bad_adder = length($zeros);

my $xbad = sprintf "x%02d", $bad_adder;
my $ybad = sprintf "y%02d", $bad_adder;

say STDERR "Suspect $xbad, $ybad";

my @which = grep { my (undef, $i1, $i2) = ($ops{$_}->@*); ($xbad eq $i1 && $ybad eq $i2) || ($xbad eq $i2 && $ybad eq $i1) } keys %ops;

my ($cr1, $cr2) = @which;

say STDERR "@which";

$bad{$cr1} = $cr2;
$bad{$cr2} = $cr1;

@ops{$cr1,$cr2} = @ops{$cr2,$cr1};

%out = run;

$xbit = join "", map { $out{$_} ? 1 : 0 } sort { $b cmp $a } grep /^x/, keys %out;
$ybit = join "", map { $out{$_} ? 1 : 0 } sort { $b cmp $a } grep /^y/, keys %out;
$zbit = join "", map { $out{$_} ? 1 : 0 } sort { $b cmp $a } grep /^z/, keys %out;

{
	use bigint;
	$x = oct("0b$xbit");
	$y = oct("0b$ybit");
	$z = oct("0b$zbit");
}

die unless ($x + $y) == $z;

say join ",", sort keys %bad;
