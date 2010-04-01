package Object::Episode::Source::Signals;
use strict;
use warnings;
use Carp;
use POSIX qw();
use Object::Episode;

use Object::Episode::OT::Array_As_Object;
use Package::Transporter sub{eval shift}, 'mix_in:hierarchy';
BEGIN {
	my $pkg = Package::Transporter->new();
	$pkg->array_indices('ATB_',[],
		qw(APPROVED  BY_SIGNAL  RECEIVED));
	$pkg->array_indices('BYS_', [SCP_PUBLIC, MIX_IMPLICIT],
		qw(IDX_FORMER  IDX_TARGETS  IDX_RECEIVED  IDX_DATA));
}

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
	$self->[ATB_BY_SIGNAL] = {};
	$self->[ATB_RECEIVED] = IS_FALSE;

	$loop->register($self);
	return;
};


#sub await_priority_primary {  return; };
sub dispatch {
	my $self = shift;

	return unless ($self->[ATB_RECEIVED]);

	my $signals = $self->[ATB_BY_SIGNAL];
	foreach my $key (keys(%$signals)) {
	    my $signal = $signals->{$key};
		next if ($signal->[BYS_IDX_RECEIVED] == 0);
		my $data = [splice(@{$signal->[BYS_IDX_DATA]})];
		foreach my $target (@{$signal->[BYS_IDX_TARGETS]}) {
			$target->hit($signal->[BYS_IDX_RECEIVED], $data);
		}
		$signal->[BYS_IDX_RECEIVED] = 0;
	}
	$self->[ATB_RECEIVED] = IS_FALSE;
	return;
}


sub register {
	my ($self, $target, $signal) = @_;

	Carp::confess($signal) unless (exists($SIG{$signal})); #ASSERTION#
	unless (exists($self->[ATB_BY_SIGNAL]{$signal})) {
		my $targets = Object::Episode::OT::Array_As_Object->new();
		$self->[ATB_BY_SIGNAL]{$signal} = [$SIG{$signal}, $targets, 0, []];
#FIXME: change this to POSIX signal handling
		my $handler_method = "SIG${signal}_handler";
		unless ($self->can($handler_method)) {
			$handler_method = "SIGX_handler";
		}
		$SIG{$signal} = $self->$handler_method($signal);

	}
	$self->[ATB_BY_SIGNAL]{$signal}[BYS_IDX_TARGETS]->push_wrap($target);
	return(IS_TRUE);
}


sub deregister {
	my ($self, $target, $signal) = @_;

	Carp::confess() unless (exists($self->[ATB_BY_SIGNAL]{$signal})); #ASSERTION#

	my $track = $self->[ATB_BY_SIGNAL]{$signal};

	$track->[BYS_IDX_TARGETS]->remove_element_WNT($target);
	if ($track->[BYS_IDX_TARGETS]->has_no_elements()) {
		$SIG{$signal} = $track->[BYS_IDX_FORMER];
		delete($self->[ATB_BY_SIGNAL]{$signal});
	}
	return(IS_TRUE);
}


sub SIGX_handler {
	my $self = shift;
	my $signal = shift;

	my $by_signal = $self->[ATB_BY_SIGNAL]{$signal};
	my $handler = undef;
	$handler = sub {
		$by_signal->[BYS_IDX_RECEIVED] += 1;
		$self->[ATB_RECEIVED] = IS_TRUE;
		$SIG{$signal} = $handler;
	};
	return($handler);
}


sub SIGCHLD_handler {
	my $self = shift;
	my $signal = shift;

	my $handler = undef;
	my $by_signal = $self->[ATB_BY_SIGNAL]{'CHLD'};
	my $received = $by_signal->[BYS_IDX_DATA];

	$handler = sub {
#FIXME: unchecked whether the constant exists...
		while ((my $child = POSIX::waitpid(-1, POSIX::WNOHANG())) > 0) {
			push(@$received, [$child, POSIX::WEXITSTATUS($?)]);
		}
		$by_signal->[BYS_IDX_RECEIVED] += 1;
		$self->[ATB_RECEIVED] = IS_TRUE;
		$SIG{'CHLD'} = $handler;
	};
	return($handler);
}


sub DESTROY {
	my $self = shift;

	if (defined($loop)) {
		$loop->deregister($self);
		$loop = undef;
	}
}


1;
