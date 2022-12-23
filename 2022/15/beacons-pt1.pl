#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }


sub bsearch ($aref, $which) {
	assert ref($aref);
	my ($lo, $hi) = (0, scalar @$aref);
	while ($lo < $hi) {
		my $cur = int(($hi - $lo) / 2 + $lo);
		my $cmp = $which <=> $aref->[$cur];
		if ($cmp == 0) {
			return $cur;
		}
		elsif ($cmp > 0) {
			$lo = $cur + 1;
		}
		else {
			$hi = $cur;
		}
	}
	return $lo;
}

sub invlist_addrange ($aref, $from, $to) {
	assert ref($aref);
	assert $from <= $to;
	++$to;
	my $pos = bsearch $aref, $from;
	if ($pos > $#$aref) {
		push @$aref, $from, $to;
		return;
	}
	if ($aref->[$pos] != $from) {
		# Inexact match
		if ($pos % 2 == 0) {
			# Currently NOT a member of the set.
			if ($to < $aref->[$pos]) {
				# Entire range is less than the next segment so insert it
				splice @$aref, $pos, 0, $from, $to;
				return;
			}
			# Otherwise we are adding a prefix of the next segment
			$aref->[$pos] = $from;
			# We should not need to merge with a previous segment because if we did $pos would've pointed at the 'end' of that segment instead.
		}
		else {
			# Starting point currently IS a member. Adjust $pos to target the entire subsegment it is contained in.
			--$pos;
		}
	}
	else {
		# Exact match
		if ($pos % 2 != 0) {
			# Currently NOT a member, adding a proper suffix to this segment.
			--$pos;
		}
		# else: Currently IS a member and is the start of a segment, no action needed.
	}
	# Now see what needs doing with the endpoint
	while ($aref->[$pos + 1] < $to) {
		# Do we need to absorb the following segment?
		if ($pos + 2 <= $#$aref && $aref->[$pos + 2] <= $to) {
			# Then yes we do. Delete the gap.
			splice @$aref, $pos + 1, 2;
		}
		else {
			# No we don't. Expand our segment.
			$aref->[$pos + 1] = $to;
		}
	}
}

sub invlist_remove ($aref, $which) {
	assert ref($aref);
	my $ix = bsearch $aref, $which;
	if ($ix > $#$aref) { return; } # Way above the current range
	if ($ix % 2 == 0) {
		# Did we exactly match the start of a segment?
		if ($aref->[$ix] == $which) {
			# Check if this becomes an empty segment
			if ($aref->[$ix + 1] == $aref->[$ix] + 1) {
				# Yes, so delete the segment
				splice @$aref, $ix, 2;
				return;
			}
			$aref->[$ix]++;
		}
		# else: Not in the list, no action needed
	}
	else {
		# Did we exactly match the end of the segment?
		if ($aref->[$ix] == $which) { return; } # Not a mebmer
		elsif ($aref->[$ix] == $which + 1) {
			# Does this become an empty segment?
			if ($aref->[$ix - 1] == $which) {
				# Yes. Delete it.
				splice @$aref, $ix - 1, 2;
				return;
			}
			$aref->[$ix]--;
		}
		else {
			# Adding a hole in the middle of a segment
			splice @$aref, $ix, 0, $which, $which + 1;
		}
	}
}

sub invlist_contains ($aref, $which) {
	assert ref($aref);
	my $ix = bsearch $aref, $which;
	if ($ix > $#$aref) { return ""; }
	return ($ix % 2 == 0) == ($aref->[$ix] == $which);
}

sub invlist_count ($aref) {
	my $ct = 0;
	for (my $ix = 0; $ix < @$aref; $ix += 2) {
		$ct += $aref->[$ix + 1] - $aref->[$ix];
	}
	return $ct;
}

my $target_row = shift(@ARGV) + 0;

my @row;

my @beacons_on_row;

while (<>) {
	chomp;
	my ($sx, $sy, $bx, $by) = /^Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)$/ or die;
	my $dist = abs($sx - $bx) + abs($sy - $by);
	my $rowdist = abs($sy - $target_row); # How far was the sensor from the Row Of Interest
	my $spread = $dist - $rowdist;
	if ($spread < 0) { next; }
	my $from = $sx - $spread;
	my $to = $sx + $spread;
	# If the becaon is ON the target row, then that spot should NOT be included. Fortunately it will always be at one
	# end or the other.
	if ($by == $target_row) {
		push @beacons_on_row, $bx;
	}
	invlist_addrange \@row, $from, $to;
}

invlist_remove \@row, $_ for @beacons_on_row;

my $score = invlist_count \@row;

say $score;
