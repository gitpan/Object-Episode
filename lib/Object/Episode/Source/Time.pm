package Object::Episode::Source::Time;
use strict;
use warnings;

use Object::Episode::OT::T;

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'ATB_', qw(APPROVED  TARGETS  TIMELINE));
};

sub T_ETERNITY() { 2**31 -1; };
my $NOW = \$Object::Episode::OT::T::NOW;

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

	$#$self = 2;
	$self->[ATB_APPROVED] = {};
	$self->[ATB_TARGETS] = {};

	use Object::Episode::OT::Array_As_Object;
	$self->[ATB_TIMELINE] = Object::Episode::OT::Array_As_Object->new([T_ETERNITY]);

	$loop->register($self);
	return;
}


sub max_timeout { return($_[0][ATB_TIMELINE][0] - $$NOW); }

sub await { sleep($_[1]); return; }

sub dispatch {
	my $self = shift;

	my $timeline = $self->[ATB_TIMELINE];
	while ($$NOW >= $timeline->first_element()) {
		my $t1 = $timeline->shift_wrap();
		my $targets = delete($self->[ATB_TARGETS]->{$t1});
		foreach my $target (@$targets) {
			$target->hit($t1);
		}
	}
	return;
}

sub register {
	my ($self, $target, $t1) = @_;

	my $targets = $self->[ATB_TARGETS];
	unless (exists($targets->{$t1})) {
	    $targets->{$t1} = Object::Episode::OT::Array_As_Object->new();
	    $self->[ATB_TIMELINE]->insert_sorted_WNT($t1);
	}
	$targets->{$t1}->push_wrap($target);

	return(IS_TRUE);
}


sub deregister {
	my ($self, $target, $t1) = @_;

	my $targets = $self->[ATB_TARGETS];
	return unless (exists($targets->{$t1}) and defined($targets->{$t1}));

	$targets->{$t1}->remove_element_WNT($target);
	if ($targets->{$t1}->has_no_elements()) {
		delete($targets->{$t1});
		$self->[ATB_TIMELINE]->remove_element_WNT($t1);
	}
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
