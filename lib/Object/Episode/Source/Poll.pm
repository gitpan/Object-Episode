package Object::Episode::Source::Poll;
use strict;
use warnings;
use bytes;
use Carp
	qw(confess);
use POSIX
	qw(floor);

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'ATB_', qw(TARGETS));
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
	$#$self = 0;

	use Object::Episode::OT::Array_As_Object;
	$self->[ATB_TARGETS] = Object::Episode::OT::Array_As_Object->new();

	$loop->register($self);
	return;
};


sub await_priority_secondary {  return; };

my $T1 = 0;
sub await {
	my $self = shift;

	return if (($$T0 - $T1) < 1);
	$T1 = $$T0;

	my $detected = 0;
	foreach my $target (@{$self->[ATB_TARGETS]}) {
		$detected += $target->poll();
	}
	return($detected);
}


sub register {
	my ($self, $target) = @_;

	push(@{$self->[ATB_TARGETS]}, $target);
	return(IS_TRUE);
}


sub deregister {
	my ($self, $target) = @_;

	$self->[ATB_TARGETS]->remove_wnt($target);
	return(IS_TRUE);
}


sub DESTROY {
	my $self = shift;

	if (defined($loop)) {
		$loop->deregister($self);
		$loop = undef;
	}
}



1;
