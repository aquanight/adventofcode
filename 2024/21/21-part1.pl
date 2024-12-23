#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %numpad_layout = (
	7 => [0, 0],
	8 => [1, 0],
	9 => [2, 0],
	4 => [0, 1],
	5 => [1, 1],
	6 => [2, 1],
	1 => [0, 2],
	2 => [1, 2],
	3 => [2, 2],
	0 => [1, 3],
	A => [2, 3],

	"" => [0, 3],
);

my %dpad_layout = (
	"^" => [1, 0],
	"A" => [2, 0],
	"<" => [0, 1],
	"v" => [1, 1],
	">" => [2, 1],

	"" => [ 0, 0],
);

my %numpad_paths = (
#	'4,A' => '>vv>',	
);
my %dpad_paths;

sub path ($from, $to, $pad, $paths) {
	my $key = "$from,$to";
	if (exists $paths->{$key}) { return $paths->{$key}; }
	my ($fx, $fy) = $pad->{$from}->@*;
	my ($tx, $ty) = $pad->{$to}->@*;
	my ($blnkx, $blnky) = $pad->{""}->@*;
	my $dx = $tx - $fx;
	my $dy = $ty - $fy;
	# Down before left, but left before up if it's safe, otherwise left after up.
	# Right/up doesn't matter, but right should come after down if it's safe.
	my $path = "";
	my $xstr = ($dx < 0 ? '<' : '>') x abs($dx);
	my $ystr = ($dy < 0 ? '^' : 'v') x abs($dy);
	if ($dx >= 0) {
		if (($blnky == $ty && $blnkx == $fx) || $dy < 0) {
			# Horizontal first
			$path = $xstr . $ystr;
		}
		else {
			$path = $ystr . $xstr;
		}
	}
	else {
		if (($blnky == $fy && $blnkx == $tx) || $dy > 0) {
			# Vertical first.
			$path = $ystr . $xstr;
		}
		else {
			# Safe to do left first
			$path = $xstr . $ystr;
		}
	}
	$paths->{$key} = $path;
	return $path;
}

sub robot ($pad, $path, $input) {
	my @input = split //, $input;
	my $steps = "";
	my $pos = "A";
	while (@input) {
		my $next = shift @input;
		$steps .= path($pos, $next, $pad, $path) . "A";
		$pos = $next;
	}
	return $steps;
}

my $score = 0;

while (<>) {
	chomp;
	my ($num) = /^(\d+)A/;
	say STDERR "Numpad: $_";
	$_ = robot(\%numpad_layout, \%numpad_paths, $_);
	say STDERR "Robot 1: $_";
	$_ = robot(\%dpad_layout, \%dpad_paths, $_);
	say STDERR "Robot 2: $_";
	$_ = robot(\%dpad_layout, \%dpad_paths, $_);
	say STDERR "Robot 3: $_";
	printf STDERR "Complexity score: value=%d, lenght=%d, score=%d\n", $num, length($_), $num * length($_);
	$score += ($num * length);
}

use Data::Dumper;

say STDERR Dumper(\%numpad_paths);
say STDERR Dumper(\%dpad_paths);

say $score;