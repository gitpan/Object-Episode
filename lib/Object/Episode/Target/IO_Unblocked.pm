package Object::Episode::Target::IO_Unblocked;
use strict;
use warnings;
use Carp
	qw(confess);
use parent qw(
	Object::Episode::Target
	Object::By::Array
);
use Object::Episode;
use Object::Episode::Source::IO_Unblocked;

use Package::Transporter sub{eval shift};

sub IO_UNBLOCKED_READ() { 0 };
sub IO_UNBLOCKED_WRITE() { 1 };

my $source = Object::Episode::Source::IO_Unblocked->new();
my @default_names = qw(
	evt_io_unblocked_read
	evt_io_unblocked_write
	evt_io_unblocked_exception
	evt_io_unblocked_validate_fh
);

sub _init {
	my ($self, $object, $name, $file_handle) = @_;

	my @callbacks = ();
	foreach my $default_name (@default_names) {
		my $callback = $self->create_callback($object, $default_name, $name);
		push(@callbacks, $callback);
	}

	@$self = ($object, \@callbacks, $file_handle, IS_FALSE, undef, fileno($file_handle));
	return;
}


sub hit { # one out of four callbacks
	return(&{$_[0][ATB_CALLBACK][$_[1]]}($_[0][ATB_OBJECT], @_));
}


sub validate_fh { return($_[0][ATB_OBJECT]->validate($_[0][ATB_DATA])); }


sub fd_clear {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_clear($_[1], $_[0][ATB_DATA]);
	return;
}
sub fd_clear_read {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_clear(IO_UNBLOCKED_READ, $_[0][ATB_DATA]);
	return;
}
sub fd_clear_write {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_clear(IO_UNBLOCKED_WRITE, $_[0][ATB_DATA]);
	return;
}

sub fd_set {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_set($_[1], $_[0][ATB_DATA]);
	return;
}
sub fd_set_read {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_set(IO_UNBLOCKED_READ, $_[0][ATB_DATA]);
	return;
}
sub fd_set_write {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_set(IO_UNBLOCKED_WRITE, $_[0][ATB_DATA]);
	return;
}

sub fd_is_set {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_is_set($_[1], $_[0][ATB_DATA]);
	return;
}
sub fd_clear_all {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_clear_all($_[0][ATB_DATA]);
	return;
};
sub fd_set_all {
	confess('Target not activated') if ($_[0][ATB_ACTIVATED] == IS_FALSE);
	$source->fd_set_all($_[0][ATB_DATA]);
	return;
};


sub activate {
	return if ($_[0][ATB_ACTIVATED] == IS_TRUE);
	if ($source->register($_[0], $_[0][ATB_DATA])) {
		$_[0][ATB_ACTIVATED] = IS_TRUE;
	}
	return;
}


sub deactivate {
	return if ($_[0][ATB_ACTIVATED] != IS_TRUE);
	if ($source->deregister($_[0], $_[0][ATB_DATA])) {
		$_[0][ATB_ACTIVATED] = IS_FALSE;
	}
	return;
}


1;
