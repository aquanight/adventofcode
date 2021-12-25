#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use integer;

use Carp ();

use Time::HiRes 'time';

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my $progstart = Time::HiRes::time;

sub elapsed { no integer; my $curtime = Time::HiRes::time; return $curtime - $progstart; }
sub elappfx { sprintf "[%8.3f] ", elapsed; }

# ALU state is given by w:x:y:z and the value is the input used as such
# If two states converge, keep the state with the better input
our %state;
=pod
sub op_add {
	$_[0] += $_[1];
};
sub op_mul {
	$_[0] *= $_[1];
};
sub op_div {
	$_[1] == 0 and Carp::confess "ALU crash";
	$_[0] /= $_[1];
};
sub op_mod {
	($_[0] < 0 || $_[1] <= 0) and Carp::confess "ALU crash";
	$_[0] %= $_[1];
};
sub op_eql {
	$_[0] = ($_[0] == $_[1] ? 1 : 0)
};
=cut

# Initialize ALU
#$state{"0:0:0:0"} = "";
$state{pack QQQQ => 0, 0, 0, 0} = "";

my $operation = "";

my %varidx = ( w => 0, x => 1, y => 2, z => 3 );
use Data::Dumper ();

sub exec_operation {
	length $operation or return;
=pod
	my $proc = eval "sub {
		my \\(\$w, \$x, \$y, \$z) = \\(\@_[0 .. 3]);
#line Operation 1
		$operation
	}"//Carp::confess "Failed to compile operation. Operation:\n$operation\nFailure: $@";
=cut
	#say STDERR Data::Dumper->Dump([\%state]);
	my %newstate;
	my $statecount = scalar keys %state;
	say STDERR elappfx . "Applying section to $statecount states ...";
	my $stime = time;
=pod
	while (defined(my $state = each %state)) {
		#for my $state (keys %state) {
		my $input = delete $state{$state};
		#my @state = map { 0 + $_ } split /:/, $state;
		my @state = unpack QQQQ => $state;
		eval {
			$proc->(@state);
			1;
		} // do {
			Carp::confess "Failed to execute operation.\nInitial state: $state\nOperation:\n$operation\nFailure: $@";
		};
		#my $newstate = join ":", @state;
		my $newstate = pack QQQQ => @state;
		#if (length $input <= 2) {
		#	say STDERR "> $state -> $newstate";
		#}
		if ($newstate{$newstate}//0 < $input) {
			$newstate{$newstate} = $input;
		}
	}
=cut
	eval (q{
		while (defined(my $state = each %state)) {
			my $input = delete $state{$state};
			my @state = unpack QQQQ => $state;
			my \\($w, $x, $y, $z) = \\(@state[0..3]);
			~~OP~~
			my $newstate = pack QQQQ => @state;
			#if (length $input <= 2) {
			#	say STDERR "> $state -> $newstate";
			#}
			if (($newstate{$newstate}//0) < $input) {
				$newstate{$newstate} = $input;
			}
		}
		1;
	} =~ s/~~OP~~/$operation/r)//do {
		Carp::confess "Failed to execute operation.\nOperation:\n$operation\nFailure: $@";
	};
	my $etime = time;
	{ no integer; printf STDERR "%sCompleted in %.3f seconds (%.3f states/second)\n", elappfx, ($etime - $stime), $statecount / ($etime - $stime); }
	\%state = \%newstate;
	$operation = "";
	#say STDERR Data::Dumper->Dump([\%state]);
}

while (<>) {
	chomp;
	if (my ($var) = /^\s*inp\s+([wxyz])\s*$/) {
		# Apply the pending operation 
		exec_operation;
		my %newstate;
		my $statecount = scalar keys %state;
		say STDERR elappfx . "Applying next input to $statecount states";
		my $stime = time;
		while (defined(my $state = each %state)) {
			#for my $state (keys %state) {
			#my @state = map { 0+$_ } split /:/, $state;
			my @state = unpack QQQQ => $state;
			my \$tgt = \$state[$varidx{$var}//die "Illegal destination '$var'"];
			my $input = delete $state{$state};
			my @add = split //, (shift @ARGV // "123456789");
			for my $add ( @add ) {
				$tgt = $add;
				#my $newstate = join ":", @state;
				my $newstate = pack QQQQ => @state;
				my $newinput = 0 + "${input}${add}";
				if (($newstate{$newstate}//0) < $newinput) {
					$newstate{$newstate} = $newinput;
				}
			}
		}
		my $etime = time;
		{ no integer; printf STDERR "%sCompleted in %.3f seconds (%.3f states/second)\n", elappfx, ($etime - $stime), $statecount / ($etime - $stime); }
		\%state = \%newstate;
	}
	elsif (my ($op, $dst, $src) = /^\s*(add|mul|div|mod|eql)\s+([wxyz])\s+([wxyz]|-?\d+)\s*$/) {
		my $psrc = $src =~ s/[wxyz]/\$$&/r;
		my $pdst = "\$$dst";
		if ($op eq "add") {
			$operation .= "$pdst += $psrc;\n";
		}
		elsif ($op eq "mul") {
			$operation .= "$pdst *= $psrc;\n";
		}
		elsif ($op eq "div") {
			# Don't forget this happens under 'use integer;'
			$operation .= "$pdst /= $psrc;\n";
		}
		elsif ($op eq "mod") {
			$operation .= "die if $pdst < 0; ";
			if ($psrc =~ m/^\$/) {
				$operation .= "die if $psrc <= 0; ";
			}
			$operation .= "$pdst %= $psrc;\n";
		}
		elsif ($op eq "eql") {
			$operation .= "$pdst = ($pdst == $psrc) ? 1 : 0;\n";
		}
		#$operation .= "op_$op \$$dst, $src;\n";
	}
}

exec_operation;

my $biggest = 0;
say STDERR "Final states: ";

for my $state (keys %state) {
	my $input = $state{$state};
	#my @state = split/:/, $state;
	my @state = unpack QQQQ => $state;
	if ($state[3] == 0) {
		say STDERR "> [ @state ] from $input";
		#say STDERR "(valid)\n";
		if ($input > $biggest) {
			$biggest = $input;
		}
	}
	#else {
	#	say STDERR "(invalid)";
	#}
}

say "Biggest valid serial: $biggest";
