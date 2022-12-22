#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %visit = ("0,0" => 1);

my @rope_xpos = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
my @rope_ypos = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

sub tail_good ($n) {
	$n < @rope_xpos or die;
	$n > 0 or die;
	my $h_xpos = $rope_xpos[$n - 1];
	my $h_ypos = $rope_ypos[$n - 1];
	my $t_xpos = $rope_xpos[$n];
	my $t_ypos = $rope_ypos[$n];
	# Tail should never get more than 1 move away from the head
	assert abs($h_xpos - $t_xpos) <= 2 && abs($h_ypos - $t_ypos) <= 2;
	return abs($h_xpos - $t_xpos) <= 1 && abs($h_ypos - $t_ypos) <= 1;
}

sub adjust_tail ($n) {
	# Since this MUST be called after every HEAD movement, we should never have to move the tail more than once.
	$n < @rope_xpos or die;
	$n > 0 or die;
	my \$h_xpos = \$rope_xpos[$n - 1];
	my \$h_ypos = \$rope_ypos[$n - 1];
	my \$t_xpos = \$rope_xpos[$n];
	my \$t_ypos = \$rope_ypos[$n];
	if (tail_good $n) { return; }
	my $dx = $h_xpos <=> $t_xpos;
	my $dy = $h_ypos <=> $t_ypos;
	move_segment($n, $dx, $dy);
	assert tail_good($n);
}

sub move_segment ($n, $dx, $dy) {
	$n < @rope_xpos or die;
	$n >= 0 or die;
	my \$h_xpos = \$rope_xpos[$n];
	my \$h_ypos = \$rope_ypos[$n];
	$h_xpos += $dx;
	$h_ypos += $dy;
	if ($dx != 0 || $dy != 0) {
		say STDERR "Segment $n: ($h_xpos, $h_ypos)";
		if ($n < $#rope_xpos) {
			adjust_tail $n + 1;
		}
	}
}

sub move_R { move_segment 0, 1, 0; }
sub move_L { move_segment 0, -1, 0; }
sub move_U { move_segment 0, 0, 1; }
sub move_D { move_segment 0, 0, -1; }

my $score = 0;

while (<>) {
	chomp;
	my ($cmd, $ct);
	($cmd, $ct) = /^([ULDR]) (\d+)$/ or die "Input problem: [$_]";
	my $proc = main->can("move_$cmd")//die "Unknown direction [$_]";
	while ($ct-- > 0) {
		$proc->();
		$visit{sprintf("%d,%d", $rope_xpos[-1], $rope_ypos[-1])} = 1;
	}
}

for (sort keys %visit) {
	say STDERR "Visited: $_";
}

$score = keys %visit;

say $score;
