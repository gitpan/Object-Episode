package Object::Episode::Paragraph::TCP_Socket_IO;
use strict;
use warnings;
use bytes;

use Carp
	qw(confess);
use POSIX
	qw(:errno_h);
use parent qw(
	Object::Episode::OT::Object_By_Array
);

use Object::Episode;
use Object::Episode::Target::IO_Unblocked;
use Object::Episode::Target::Timeout;

use Package::Transporter sub{eval shift}, 'mix_in:hierarchy';
BEGIN {
	my $pkg = Package::Transporter->new();
	$pkg->array_indices('BST_', [], qw(CLOSED  BUSY  IDLE));
	$pkg->array_indices('ATB_', [],
		qw(PROTOCOL  SOCKET  IO_UNBLOCKED
		IBUF  OBUF  IBUF_STATE  OBUF_STATE  TIMEOUT));
}


$SIG{'PIPE'} = 'IGNORE'; # enables EPIPE globally to avoid sysaction() flooding

#WARNING: This module is not symmetric! Reading is not the opposite,
# reverse or mirror of writing.

sub _init {
	my ($self, $protocol, $socket, $io_timeout) = @_;

	$self->[ATB_PROTOCOL] = $protocol;
	$self->[ATB_SOCKET] = $socket;

	my $io_unblocked = Object::Episode::Target::IO_Unblocked->
		new_active($self, undef, $socket);
	$io_unblocked->fd_set_read;
	$self->[ATB_IO_UNBLOCKED] = $io_unblocked;

	$self->[ATB_IBUF] = '';
	$self->[ATB_OBUF] = '';
	$self->[ATB_IBUF_STATE] = BST_IDLE;
	$self->[ATB_OBUF_STATE] = BST_IDLE;

	$self->[ATB_TIMEOUT] = Object::Episode::Target::Timeout->
		new_active($self, undef, $io_timeout);
}


sub evt_time_timeout { $_[0]->drop(); }

sub evt_io_unblocked_validate_fh {}; # not implemented, yet
sub evt_io_unblocked_exception {}; # no exchange of OOB-Data over Sockets
sub evt_io_unblocked_read {
	my ($self) = @_;

	return() if ($self->[ATB_IBUF_STATE] == BST_CLOSED);
	$self->[ATB_TIMEOUT]->refresh();

	READ: {
		my $n = sysread($self->[ATB_SOCKET], my $buffer, 2**15);
#		print STDERR "got $n bytes, |$buffer|\n";
		unless (defined($n)) { # mostly ($! == EPIPE)
#FIXME: log $!
			redo READ if ($self->is_temporary_error());
			$self->drop();
			return();
		};
		if ($n == 0) { # eof for non-blocking case
			$self->drop();
			return();
		}
		$self->[ATB_IBUF] .= $buffer;
	}

	if (length($self->[ATB_IBUF]) > 0) {
		$self->[ATB_PROTOCOL]->evt_tcp_socket_io_arrived(\$self->[ATB_IBUF]);
	}
	return();
}


sub evt_io_unblocked_write {
	my ($self) = @_;

#	print STDERR "evt_fh_write_wnb\n";
	return() if ($self->[ATB_OBUF_STATE] == BST_CLOSED); # no point
#	    print STDERR "State open.\n";
	if (length($self->[ATB_OBUF]) == 0) { # $n == 0 indicates eof
#	    print STDERR "OBUF empty.\n";

		$self->[ATB_IO_UNBLOCKED]->fd_clear_write();
		$self->[ATB_PROTOCOL]->evt_tcp_socket_io_departed(IS_TRUE);
		return();
	}
	$self->[ATB_TIMEOUT]->refresh();

	WRITE: {
		my $n = syswrite($self->[ATB_SOCKET], $self->[ATB_OBUF], 2**15);
#		print STDERR "wrote $n bytes\n";
		unless (defined($n)) {
#FIXME: log $!
			return() if ($self->is_temporary_error());
			$self->drop();
			return();
		};
		if ($n == 0) { # eof
			$self->drop();
			return();
		}
#		$self->[ATB_OBUF]->take($n);
		substr($self->[ATB_OBUF], 0, $n, '');
	}

	if (length($self->[ATB_OBUF]) == 0) {
		$self->[ATB_IO_UNBLOCKED]->fd_clear_write();
		$self->[ATB_OBUF_STATE] = BST_IDLE;
		$self->[ATB_PROTOCOL]->evt_tcp_socket_io_departed(IS_TRUE);
	}
	return();
}


sub add_to_outbuffer {
	my $self = shift();

	return() if ($self->[ATB_OBUF_STATE] == BST_CLOSED); # no point
	$self->[ATB_OBUF] .= ${$_} foreach @_;

	if (($self->[ATB_OBUF_STATE] == BST_IDLE)
	and (length($self->[ATB_OBUF]) > 0)) {
#	    print STDERR "Enabling writing from outbuffer\n";
		$self->[ATB_IO_UNBLOCKED]->fd_set_write;
		$self->[ATB_OBUF_STATE] = BST_BUSY;
		$self->[ATB_PROTOCOL]->evt_tcp_socket_io_departed(IS_FALSE);
	}
	return();
};


sub is_temporary_error {
	if (($! == EAGAIN) or ($! == EINTR) or ($! == EINPROGRESS) or
	   ($! == ENOMEM)) {
		return(IS_TRUE);
	}
	return(IS_FALSE);
}


sub is_alive { return(IS_TRUE) }; # FIXME


sub drop {
	my $self = shift();

	return() unless (defined($self->[ATB_PROTOCOL]));

	$self->[ATB_TIMEOUT]->deactivate();
	$self->[ATB_TIMEOUT] = undef;
	$self->[ATB_IO_UNBLOCKED]->deactivate();
	$self->[ATB_IO_UNBLOCKED] = undef;

#	my $fd = fileno($self->[ATB_SOCKET]);
#	POSIX::close($fd) || warn("FD$fd: close: $!");

	$self->[ATB_IBUF_STATE] = BST_CLOSED;
	$self->[ATB_OBUF_STATE] = BST_CLOSED;

	$self->[ATB_PROTOCOL]->evt_tcp_socket_io_drop();
	$self->[ATB_PROTOCOL] = undef;
	return();
}


sub set_timeout {
	if ($_[1] == 0) {
		$_[0][ATB_TIMEOUT]->deactivate();
	} else {
		$_[0][ATB_TIMEOUT]->adjust($_[1]);
	}
	return();
}

sub set_bst_in_closed {
	$_[0][ATB_IBUF_STATE] = BST_CLOSED;
	$_[0][ATB_IO_UNBLOCKED]->fd_clear_read();
	return();
};
sub set_bst_out_closed {
	$_[0][ATB_OBUF_STATE] = BST_CLOSED;
	$_[0][ATB_IO_UNBLOCKED]->fd_clear_write();
	return();
};

#sub is_bst_in { return($_[0][ATB_IBUF_STATE] == BST_CLOSED); };
#sub is_bst_out { return($_[0][ATB_OBUF_STATE] == BST_CLOSED); };


sub DESTROY {
	foreach my $attribute (ATB_IO_UNBLOCKED, ATB_TIMEOUT) {
		if (defined($_[0][$attribute])) {
			$_[0][$attribute]->deactivate();
		}
	}
}


1;
