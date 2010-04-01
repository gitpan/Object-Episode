package Object::Episode::Source::IO_Unblocked;
use strict;
use warnings;
use bytes;
use Carp
	qw(confess);
use POSIX
	qw(floor);

my $FD_MAX = eval { POSIX::sysconf(&POSIX::_SC_OPEN_MAX) - 1 } || 1023;

my $null_byte = pack('x', 0);

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'ATB_', qw(WANTS  GOT  DETECTED  TARGETS  ZEROS));
	$_[0]->register_drain('::Enumerated', 'FOR_FAMILY',
		'IO_UNBLOCKED_', qw(READ  WRITE  EXCEPTION));
};

my @SELF = ();
sub new {
	my $class = shift;

	my $self = \@SELF;
	bless($self, $class);
	$self->_init(@_) unless (@SELF);
	return($self);
}


use Object::Episode::Loop;
my $loop = Object::Episode::Loop->new();
sub _init {
	my $self = shift;

	$#$self = 4;
	$self->[ATB_WANTS] = ['', '', ''];
	$self->[ATB_GOT] = ['', '', ''];
	$self->[ATB_DETECTED] = 0;

	use Object::Episode::OT::Array_As_Object;
	$self->[ATB_TARGETS] = Object::Episode::OT::Array_As_Object->new();
	$self->[ATB_ZEROS] = '';

	$loop->register($self);
	return;
};


sub await_priority_primary {  return; };
sub await {
	my $self = shift;
	my $timeout = $_[0]; $_[0] = 0;


	$self->[ATB_DETECTED] = 0;
	my $got = $self->[ATB_GOT];
	my $wants = $self->[ATB_WANTS];
	$got->[IO_UNBLOCKED_READ] = $wants->[IO_UNBLOCKED_READ];
	$got->[IO_UNBLOCKED_WRITE] = $wants->[IO_UNBLOCKED_WRITE];
	$got->[IO_UNBLOCKED_EXCEPTION] = $wants->[IO_UNBLOCKED_EXCEPTION];

	my $waiting = IS_TRUE;
	while ($waiting < 10) {
#	    print STDERR "---------------------------------------\n";
#	$self->dump_vectors(SI_GOT, IO_UNBLOCKED_READ, IO_UNBLOCKED_WRITE);
		my $found = select($got->[IO_UNBLOCKED_READ], $got->[IO_UNBLOCKED_WRITE], $got->[IO_UNBLOCKED_EXCEPTION], $timeout);
#	$self->dump_vectors(SI_GOT, IO_UNBLOCKED_READ, IO_UNBLOCKED_WRITE);
		if ($found == -1) {
			$waiting += 1;
			next unless ($self->sys_EXXX());
			last;
		}
		$self->[ATB_DETECTED] = $found;
		last;
	}
	return($self->[ATB_DETECTED]);
}


sub sys_EXXX {
	my $self = shift;

	if ($! == POSIX::EBADF) {
		# An invalid file descriptor was given in one of the sets.
#D#			$self->fd_info();
#D#			$self->dump(SI_WANTS, IO_UNBLOCKED_READ, IO_UNBLOCKED_WRITE);
#D#			$self->dump(SI_GOT, IO_UNBLOCKED_READ, IO_UNBLOCKED_WRITE);
		$self->validate_target_fhs();
	} elsif (($! == POSIX::EAGAIN) or ($! == POSIX::EINTR) or
			($! == POSIX::EINPROGRESS) or ($! == POSIX::ENOMEM)) {
		return(IS_TRUE);
	} elsif ($! == POSIX::EINVAL) {
		# n is negative or the value contained within timeout is invalid.
	} else {
#D#			print STDERR "got errno=", int($!), "#\n"; # what a lousy language
	}
	return(IS_FALSE);
}


sub dispatch {
	my $self = shift;

	return unless ($self->[ATB_DETECTED]);

	my $got = $self->[ATB_GOT];
	my @r_bytes = map(unpack("C", $_),
		split('', $got->[IO_UNBLOCKED_READ]));
	my @w_bytes = map(unpack("C", $_),
		split('', $got->[IO_UNBLOCKED_WRITE]));
	my @e_bytes = map(unpack("C", $_),
		split('', $got->[IO_UNBLOCKED_EXCEPTION]));
	my $left = $self->[ATB_DETECTED];

	my $targets = $self->[ATB_TARGETS];
	my $i = -1;
BYTE: while ($#r_bytes > -1) {
		my @got = (shift(@r_bytes), shift(@w_bytes), shift(@e_bytes));
		my $got_any = $got[IO_UNBLOCKED_READ] + $got[IO_UNBLOCKED_WRITE]
			+ $got[IO_UNBLOCKED_EXCEPTION];
		if ($got_any == 0) {
			$i += 8;
			next;
		}
		foreach my $mask (1, 2, 4, 8, 16, 32, 64, 128) {
			$i += 1;
			my @flags = (($got[IO_UNBLOCKED_READ] & $mask),
					 ($got[IO_UNBLOCKED_WRITE] & $mask),
					 ($got[IO_UNBLOCKED_EXCEPTION] & $mask));
			my $flagged = $flags[0] +$flags[1] +$flags[2];
			if ($flagged > 0) {
				my $target = $targets->[$i];
				# evt_io_exception
				$target->hit(2, $i) if ($flags[2]);
				# evt_io_unblocked_read
				$target->hit(0, $i) if ($flags[0]);
				# evt_io_unblocked_write
				$target->hit(1, $i) if ($flags[1]);
				$left -= $flagged;
			}
			last BYTE if ($left == 0);
		}
	}
	return;
}


sub register { # allocates space
	my ($self, $target, $fd) = @_;

	confess unless (($fd > -1) and ($fd < $FD_MAX)); #ASSERTION#

	my $l = length($self->[ATB_ZEROS]);
	my $enlarge = (int($fd/8) -$l +1);
	if ($enlarge > 0) {
		my $extension = $null_byte x $enlarge;
		$self->[ATB_ZEROS] .= $extension;
		map($_ .= $extension, @{$self->[ATB_WANTS]}, @{$self->[ATB_GOT]});
	}

#	confess() unless (defined($caller)); #DEBUG#
#	print STDERR "$$ register $caller fd=$fd\n";
	$self->[ATB_TARGETS][$fd] = $target;
	return(IS_TRUE);
}


sub deregister { # releases space
	my ($self, $target, $fd) = @_;

	map(vec($_, $fd, 1) = 0, @{$_[0][ATB_WANTS]}, @{$_[0][ATB_GOT]});

	my $targets = $self->[ATB_TARGETS];
	$targets->[$fd] = undef;
	$targets->remove_undefined_at_end();

	my $downsize = (POSIX::floor($#{$self->[ATB_TARGETS]} /8) +1
					-length($self->[ATB_ZEROS]));
	if ($downsize) {
		substr($self->[ATB_ZEROS], -$downsize) = '';
		map(substr($_, -$downsize) = '',
			@{$self->[ATB_WANTS]}, @{$self->[ATB_GOT]});
	}

	return(IS_TRUE);
}


sub fd_zero   { $_[0][ATB_WANTS][$_[1]] =
		$_[0][ATB_WANTS][$_[1]] ^ $_[0][ATB_WANTS][$_[1]]; return; };

sub fd_clear  { vec($_[0][ATB_WANTS][$_[1]], $_[2], 1) = 0; return; };
sub fd_set    {	vec($_[0][ATB_WANTS][$_[1]], $_[2], 1) = 1; return; };

sub fd_clear_all { map(vec($_, $_[1], 1) = 0, @{$_[0][ATB_WANTS]}); return; };
sub fd_set_all { map(vec($_, $_[1], 1) = 1, @{$_[0][ATB_WANTS]}); return; };

sub fd_is_set { (vec($_[0][ATB_GOT][$_[1]], $_[2], 1) == 1) ? IS_TRUE : IS_FALSE };


sub watches {
	my $self = shift;
	my $what = shift;

	return(($self->[ATB_WANTS][$what] eq $self->[ATB_ZEROS]) ? IS_FALSE : IS_TRUE);
}


sub are_empty {
	my $self = shift;

	my $empty_or_not = IS_TRUE;
	foreach (@_) {
		next if ($self->[ATB_WANTS][$_] eq $self->[ATB_ZEROS]);
		$empty_or_not = IS_FALSE;
		last;
	}
	return($empty_or_not);
}


#sub visited_all {
#	my $self = shift;
#	my $what = shift;
#
#	my $rv =(((not defined($self->[ATB_GOT][IO_UNBLOCKED_READ]) or
#			   ($self->[ATB_GOT][IO_UNBLOCKED_READ] eq $self->[ATB_ZEROS])) and
#			  (not defined($self->[ATB_GOT][IO_UNBLOCKED_WRITE]) or
#			   ($self->[ATB_GOT][IO_UNBLOCKED_WRITE] eq $self->[ATB_ZEROS])) and
#		  (not defined($self->[ATB_GOT][IO_UNBLOCKED_EXCEPTION]) or
#		   ($self->[ATB_GOT][IO_UNBLOCKED_EXCEPTION] eq $self->[ATB_ZEROS])))
#		? IS_TRUE : IS_FALSE);
#	return($rv);
#}

sub validate_target_fhs {
	my $self = shift;

	foreach my $target (@{$self->[ATB_TARGETS]}) {
		next unless (defined($target));
		$target->hit(3); # evt_io_validate_fh
	}
	return;
}


sub clear {
	my $self = shift;

	$self->[ATB_GOT][IO_UNBLOCKED_READ] = $self->[ATB_ZEROS];
	$self->[ATB_GOT][IO_UNBLOCKED_WRITE] = $self->[ATB_ZEROS];
	$self->[ATB_GOT][IO_UNBLOCKED_EXCEPTION] = $self->[ATB_ZEROS];
	return;
}


sub DESTROY {
	my $self = shift;

	if (defined($loop)) {
		$loop->deregister($self);
		$loop = undef;
	}
}



1;

__END__
# -------------------------------------------------------------------------
sub dump_vectors { # debugging aid
	my $self = shift;
	my $what = shift;

	my $ds = 'W';
	$ds = 'G' if ($what == ATB_GOT);
	my $pid = sprintf('%5s', $$);
	print STDERR "$pid $0 ";
	foreach (@_) {
		print STDERR " $ds$_: ", unpack('b*', $self->[$what][$_]);
	}
	print STDERR "\n";
	return;
}


sub fd_info { # debugging aid under Linux
	my $self = shift;

	my $l = length($self->[ATB_ZEROS]) * 8;
	foreach my $i (0..$l) {
		next unless (-e "/proc/$$/fd/$i");
		print STDERR "FD $i in $$ $0 connected to ",
			readlink("/proc/$$/fd/$i"), "\n";
	}
	return;
}


#sub fd_was_set {
#	my $rv = fd_is_set@_;
#	vec($_[0][ATB_GOT][$_[1]], $_[2], 1) = 0;
#	return($rv);
#};

#sub fds_are_set {
#	my ($self, $fds, $wants) = @_;
#
#	my $set = $self->[$wants];
#	my $l = length($self->[ATB_ZEROS]);
#	my $downsize = 0;
#	for (my $i = 0; $i < $l; $i += 1) {
#		if (substr($self->[ATB_ZEROS], $i, 1) eq $null_byte) {
#			$downsize += 1;
#			next;
#		}
#		last;
#	}
#
#};
