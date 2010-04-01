package Object::Episode::Group;
use strict;
use warnings;
use Object::Episode;

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'ATB_', qw(TARGETS));
};

sub _init {
	my $self = shift;

	use Object::Episode::OT::Array_As_Object;
	$self->[ATB_TARGETS] = Object::Episode::OT::Array_As_Object->new();
	return;
};


sub intercept { map($_->intercept, @{$_[0][ATB_TARGETS]}); return; }
sub pass { map($_->pass, @{$_[0][ATB_TARGETS]}); return; }

sub add { shift->[ATB_TARGETS]->push_if_distinct_WNT(@_); return; }
sub remove { shift->[ATB_TARGETS]->remove_element_WNT(@_); return; }


1;
