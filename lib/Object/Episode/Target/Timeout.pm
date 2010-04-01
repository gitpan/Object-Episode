package Object::Episode::Target::Timeout;
use strict;
use warnings;
use Carp
	qw(confess);
use parent qw(
	Object::Episode::Target
	Object::Episode::OT::Object_By_Array
);
use Object::Episode;
use Object::Episode::OT::T;
my $NOW = \$Object::Episode::OT::T::NOW;

use Package::Transporter sub{eval shift};
use Object::Episode::Source::Time;
use Object::Episode::OT::T qw($NOW);

my $source = Object::Episode::Source::Time->new();


my $default_name = 'evt_time_timeout';
sub _init {
	my ($self, $object, $name, $after) = @_;

	my $callback = $self->create_callback($object, $default_name, $name);
	$after = 60 if ($after == 0);
	@$self = ($object, $callback, 0, IS_FALSE, undef, $after);
	return;
}


sub remaining { return($_[0][ATB_VALUE] - $$NOW); }
sub refresh {
	$_[0]->reset() if (($_[0][ATB_VALUE] - $$NOW) < ($_[0][ATB_DATA]/3));
	return;
}
sub reset { $_[0]->deactivate(); $_[0]->activate(); return; }
sub adjust {
	$_[0]->deactivate();
	$_[0][ATB_DATA] = $_[1];
	$_[0]->activate();
	return;
}
sub reactivate {
	$_[0][ATB_ACTIVATED] = IS_FALSE;
	$_[0]->activate();
	return;
}


sub activate {
	return if ($_[0][ATB_ACTIVATED] == IS_TRUE);
	$_[0][ATB_VALUE] = $$NOW + $_[0][ATB_DATA];
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
