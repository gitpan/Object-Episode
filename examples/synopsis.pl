use strict;
use Object::Episode;
use Object::Episode::Synopsis; 

my $loop = Object::Episode::Loop->new();
my $callback = Event_Demo1->new($loop->control);

my @events = Object::Episode::Synopsis->recognize($callback,
	'every 1 second',	# $callback->evt_time_periodic
	'at hour 23',		# $callback->evt_time_wallclock
	'in 20 seconds',	# $callback->evt_time_timeout
	'SIGUSR1',		# $callback->evt_signal_usr1
	sub { return((-e '/tmp/any.txt') ? 1 : 0) }
				# $callback->evt_poll_edge_test1
);

$loop->run();

map($_->deactivate, @events);
exit(0);

BEGIN {
package Event_Demo1;
use POSIX qw();

sub new	{ bless($_[1], $_[0]); } # $self holds the loop control

# standard event methods
sub evt_time_periodic	{ print STDERR "."; }
sub evt_time_wallclock	{ print STDERR "W"; }
sub evt_time_timeout	{ print STDERR "T"; kill(&POSIX::SIGUSR1, $$); }
sub evt_signal_usr1	{ print STDERR "S\n"; ${$_[0]} = 0; }
sub evt_poll_edge_test1	{ print STDERR "P$_[1]"; }
}
