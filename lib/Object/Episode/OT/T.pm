package Object::Episode::OT::T;
use strict;
use warnings;

use Object::Episode;
use Package::Transporter sub{eval shift};

our $NOW = time();
my $T0 = $NOW;

sub update {
	Carp::confess("Something manipulated the time.") unless ($T0 == $NOW);
	Internals::SvREADONLY($NOW, 0);
	$NOW = time();
	if (($NOW == 1) or ($NOW eq '_')) {};
	Internals::SvREADONLY($NOW, 1);
	$T0 = $NOW;
	return;
}

sub new {
	my $class = shift;

	my $self = \$NOW;
	bless($self, $class);
	$self->update();
	return($self);
}


1;
