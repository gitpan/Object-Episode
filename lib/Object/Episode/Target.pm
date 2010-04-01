package Object::Episode::Target;
use strict;
use warnings;
use Carp qw();

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_FAMILY',
		'ATB_', qw(OBJECT CALLBACK VALUE ACTIVATED INTERCEPTED DATA));
};

sub new_active { 
	my $obj = shift->new(@_);
	$obj->activate;
	return($obj);
};

sub is_activated { return($_[0][ATB_ACTIVATED]) };


sub hit {
	if(defined($_[0][ATB_INTERCEPTED])) {
		push(@{$_[0][ATB_INTERCEPTED]}, \@_);
		return;
	}
	return(&{$_[0][ATB_CALLBACK]}($_[0][ATB_OBJECT], @_));
}


sub create_callback {
	my ($self, $object, $default_name, $name) = @_;

	my $method;
	if (defined($name)) {
		if (substr($name, 0, 1) eq '_') {
			$method = $default_name . $name;
		} else {
			$method = $name;
		}
	} else {
		$method = $default_name;
	}
	my $callback = $object->can($method);
	Carp::confess("No method '$method' on object '$object'.") unless ($callback);
	return($callback);
}


sub intercept {
	$_[0][ATB_INTERCEPTED] = [];
	return;
}


sub drop_intercepted {
	$_[0][ATB_INTERCEPTED] = undef;
	return;
}


sub pass {
	return unless(defined($_[0][ATB_INTERCEPTED]));
	my $intercepted = $_[0][ATB_INTERCEPTED];
        $_[0][ATB_INTERCEPTED] = undef;
	foreach my $item (@$intercepted) {
		$_[0]->hit(@$item);
	}
	return;
}


1;
