package Object::Episode::Target::Wallclock;
use strict;
use warnings;
use Carp
	qw(confess);
use parent qw(
	Object::Episode::Target
	Object::By::Array
);
use Object::Episode;
use Object::Episode::OT::T;
my $NOW = \$Object::Episode::OT::T::NOW;

use Package::Transporter sub{eval shift};

use Object::Episode::Source::Time;
my $source = Object::Episode::Source::Time->new();

my $default_name = 'evt_time_wallclock';
sub _init {
	my ($self, $object, $name, $value) = @_;

	my $callback = $self->create_callback($object, $default_name, $name);
	@$self = ($object, $callback, $value, IS_FALSE, undef);
	return;
}


sub activate {
	return if ($_[0][ATB_ACTIVATED] == IS_TRUE);
	if ($source->register($_[0], $_[0][ATB_VALUE])) {
		$_[0][ATB_ACTIVATED] = IS_TRUE;
	}
	return;
}


sub deactivate {
	return if ($_[0][ATB_ACTIVATED] != IS_TRUE);
	if ($source->deregister($_[0], $_[0][ATB_VALUE])) {
		$_[0][ATB_ACTIVATED] = IS_FALSE;
	}
	return;
}


1;
