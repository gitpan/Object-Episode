package Object::Episode::Target::Periodic;
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
my $source = Object::Episode::Source::Time->new();

my $default_name = 'evt_time_periodic';
sub _init {
	my ($self, $object, $name, $period) = @_;

	my $callback = $self->create_callback($object, $default_name, $name);
	@$self = ($object, $callback, undef, IS_FALSE, undef, $period);
}


sub hit {
	my $rv = &{$_[0][ATB_CALLBACK]}($_[0][ATB_OBJECT], @_);
	$_[0]->reactivate();
	return($rv);
}


sub reactivate {
	my ($self) = @_;

	$self->[ATB_VALUE] += $self->[ATB_DATA];
	if ($source->register($self, $self->[ATB_VALUE])) {
		$self->[ATB_ACTIVATED] = IS_TRUE;
	}
	return;
}

sub activate {
	my ($self) = @_;

	return if ($self->[ATB_ACTIVATED] == IS_TRUE);
	$self->[ATB_VALUE] = $$NOW + $self->[ATB_DATA];
	if ($source->register($self, $self->[ATB_VALUE])) {
		$self->[ATB_ACTIVATED] = IS_TRUE;
	}
	return;
}


sub deactivate {
	my ($self) = @_;

	return if ($self->[ATB_ACTIVATED] != IS_TRUE);
	if ($source->deregister($self, $self->[ATB_VALUE])) {
		$self->[ATB_ACTIVATED] = IS_FALSE;
	}
	return;
}


1;
