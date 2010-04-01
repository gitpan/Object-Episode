package Object::Episode::Paragraph::Poll_Edge;
use strict;
use warnings;
use Carp
	qw(confess);
use Object::Episode::Target::Periodic;
use parent qw(
	Object::Episode::OT::Object_By_Array
);

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'ATB_', qw(TARGET OBJECT CALLBACK TEST RESULT));
};

my $default_name = 'evt_poll_edge';
sub _init {
	my ($self, $object, $name, $test, $period) = @_;

	my $target = Object::Episode::Target::Periodic->new_active(
		$self, undef, $period || 60);
	my $callback = $target->create_callback($object, $default_name, $name);
	my $result = $test->();
	@$self = ($target, $object, $callback, $test, $result);
	return;
}

sub evt_time_periodic {
	my $result = $_[0][ATB_TEST]->();
	if ($result ne $_[0][ATB_RESULT]) { # call on edge only
		$_[0][ATB_RESULT] = $result;
		return(&{$_[0][ATB_CALLBACK]}($_[0][ATB_OBJECT], $result));
	}
	return;
}

sub DESTROY {
	if(defined($_[0]) and defined($_[0][ATB_TARGET])) {
		$_[0][ATB_TARGET]->deactivate;
	}
}

1;
