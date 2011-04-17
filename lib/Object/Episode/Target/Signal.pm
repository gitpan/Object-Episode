package Object::Episode::Target::Signal;
use strict;
use warnings;
use Carp
	qw(confess);
use parent qw(
	Object::Episode::Target
	Object::By::Array
);
use Object::Episode;

use Package::Transporter sub{eval shift};
use Object::Episode::Source::Signals;

$SIG{'PIPE'} = 'IGNORE'; # not ignoring would disable the required EPIPE


my $source = Object::Episode::Source::Signals->new();

my $default_name = 'evt_signal_';
sub _init {
	my ($self, $object, $name, $signal) = @_;
	confess('Would disable the required EPIPE.') if ($signal eq 'PIPE');

	my $callback = $self->create_callback($object, $default_name.lc($signal), $name);
	@$self = ($object, $callback, $signal, IS_FALSE, undef);
}


sub activate {
	return if ($_[0][ATB_ACTIVATED] == IS_TRUE);
	if ($source->register($_[0], $_[0][ATB_VALUE])) {
		$_[0][ATB_ACTIVATED] = IS_TRUE;
	}
}


sub deactivate {
	return if ($_[0][ATB_ACTIVATED] != IS_TRUE);
	if ($source->deregister($_[0], $_[0][ATB_VALUE])) {
		$_[0][ATB_ACTIVATED] = IS_FALSE;
	}
}


1;
