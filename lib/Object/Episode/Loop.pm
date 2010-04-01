package Object::Episode::Loop;
use strict;
use warnings;
use Object::Episode;

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'ATB_', qw(BY_CAPABILITY  MAX_TIMEOUT  IS_RUNNING  LEAVE));
	$_[0]->register_drain('::Enumerated', 'FOR_SELF',
		'AWT_', qw(PRIO_PRIMARY  PRIO_SECONDARY));
};


my @SELF = ();
sub new {
	my $class = shift;

	my $self = \@SELF;
	bless($self, $class);
	$self->_init(@_) unless (@SELF);
	return($self);
}

use Object::Episode::OT::T;
my $now = Object::Episode::OT::T->new();

sub _init {
	my $self = shift;

	if(exists($_[0])) {
		$self->[ATB_MAX_TIMEOUT] = shift;
	}

	use Object::Episode::OT::Array_As_Object;
	$self->[ATB_BY_CAPABILITY] = {
		'await' => Object::Episode::OT::Array_As_Object->new([$self]),
		'dispatch' => Object::Episode::OT::Array_As_Object->new(),
		'max_timeout' => Object::Episode::OT::Array_As_Object->new(),
	};
	$self->[ATB_MAX_TIMEOUT] = 30;
	$self->[ATB_IS_RUNNING] = [];
	return;
};


sub register {
	my ($self, $source) = @_;

	my $by_capability = $self->[ATB_BY_CAPABILITY];

	my $priority = $source->can('await_priority_primary') ?
		AWT_PRIO_PRIMARY : AWT_PRIO_SECONDARY;
	foreach my $key (keys(%$by_capability)) {
		next unless ($source->can($key));
		if ($priority == AWT_PRIO_PRIMARY) {
			$by_capability->{$key}->unshift_wrap($source);
		} else {
			$by_capability->{$key}->push_wrap($source);
		}
	}
	return;
}


sub deregister {
	my ($self, $source) = @_;

	my $by_capability = $self->[ATB_BY_CAPABILITY];
	foreach my $key (keys(%$by_capability)) {
		next unless ($source->can($key));
		$by_capability->{$key}->remove_element_WNT($source);
	}
	return;
}


sub control {
	my $continue_flag = 1;
	push(@{$_[0][ATB_IS_RUNNING]}, \$continue_flag);

	return(\$continue_flag);
}


sub is_running { return(@{$_[0][ATB_IS_RUNNING]}); };

sub await { sleep($_[1]); return; }
sub run {
	my $self = shift;

	my $is_running = $self->[ATB_IS_RUNNING];
	if(exists($_[0])) {
		push(@$is_running, (ref($_[0]) eq '') ? \$_[0] : $_[0]);
	}
	return if (@$is_running > 1);

	my $rounds = 0;
	while (@{$is_running}) {
		unless (${$is_running->[-1]}) {
			pop(@$is_running);
			next;
		}
		unless (${$is_running->[0]}) {
			shift(@$is_running);
			next;
		}
		$rounds += 1;
		if ($rounds > 100) {
			$rounds = 0;
			if(@$is_running > 100) {
				@$is_running = grep(defined($_), @$is_running);
			}
		}
		my $timeout = $self->[ATB_MAX_TIMEOUT];
		$now->update();
		foreach my $source (@{$self->[ATB_BY_CAPABILITY]{'max_timeout'}}) {
			my $t1 = $source->max_timeout($timeout);
			$timeout = restrict_to_range($t1, 0, $timeout);
			last if ($timeout == 0);
		}

		foreach my $source (@{$self->[ATB_BY_CAPABILITY]{'await'}}) {
			$source->await($timeout);
			last;
		}

		$now->update();
		foreach my $source (@{$self->[ATB_BY_CAPABILITY]{'dispatch'}}) {
			$source->dispatch();
		}
	}
	return;
}


sub restrict_to_range($$$) {
        ($_[0] > $_[2]) ? $_[2] : (($_[0] < $_[1]) ? $_[1] : $_[0]);
};


1;
