package Object::Episode::Synopsis;
use strict;
use warnings;
use Carp
	qw(confess);

use Object::Episode;
use Time::Local;

use Object::Episode::Target::Periodic;
use Object::Episode::Target::Wallclock;
use Object::Episode::Target::Timeout;
use Object::Episode::Target::Signal;
use Object::Episode::Target::IO_Unblocked;
use Object::Episode::Paragraph::Poll_Edge;

use Package::Transporter sub{eval shift};


my %relative_units = (
        's' => 1,
        'm' => 60,
        'h' => 3600,
        'd' => 86400,
        'w' => 86400 * 7,
);

my %absolute_prefixes = (
        'second' => 0,
        'minute' => 1,
        'hour' => 2,
        'day' => 3,
        'month' => 4,
        'year' => 5
);

my $poll_edge_tests = 0;
my %increments = (
	'time_periodic' => 0,
	'time_wallclock' => 0,
	'time_timeout' => 0,
	'poll_edge' => 0,
);

sub recognize {
	my ($class, $object) = (shift, shift);

	my @targets = map(_recognize($object, $_), @_);
	return(@targets);
}

sub _recognize {
	my ($object, $value) = @_;

	if(ref($value) eq 'CODE') {
		$increments{'poll_edge'} += 1;
		return(Object::Episode::Paragraph::Poll_Edge->new($object, "_test$increments{'poll_edge'}", $value, 2));
	} elsif($value =~ m,^(every|in)[\s\t]+(\d+)[\s\t]*(s(?:econds?)?|m(?:minutes?)?|h(?:hours?)?|d(?:days?)?|w(?:weeks?)?)?$,sgi) {
		my ($mode, $seconds, $unit) = ($1, $2, substr($3, 0, 1));
		$unit = 's' unless(defined($unit));
		confess() unless(exists($relative_units{$unit}));
		$seconds *= $relative_units{$unit};
		$seconds = 10 if($seconds < 1);
		if($mode eq 'every') {
			my $ext = (($increments{'time_periodic'}++ == 0) ? undef : "_$increments{'time_periodic'}");
			return(Object::Episode::Target::Periodic->new_active($object, $ext, $seconds));
		} else { # 'in'
			my $ext = (($increments{'time_timeout'}++ == 0) ? undef : "_$increments{'time_timeout'}");
			return(Object::Episode::Target::Timeout->new_active($object, $ext, $seconds));
		}
	} elsif($value =~ s/^at[\s\t]+//sg) {
		my @e = ();
		while($value =~ s/^[\s\t]*(second|minute|hour|day|month|year)[\s\t]+(\d{1,4})//sg) {
			push(@e, [$2, $1]);
		}
		my $ext = (($increments{'time_wallclock'}++ == 0) ? undef : "_$increments{'time_wallclock'}");
		my $seconds = postfix_date_format(@e);
		return(Object::Episode::Target::Wallclock->new_active($object, $ext, $seconds));
	} elsif($value =~ m,^(SIG)(\w+)$,sgi) {
		return(Object::Episode::Target::Signal->new_active($object, undef, $2));
	} elsif(defined(fileno($value))) {
		return(Object::Episode::Target::IO_Unblocked->new_active($object, undef, $value));
	}
}



sub postfix_date_format {

	my $now = time;
	my @now = localtime($now);
	$now[4] -= 1;
	$now[1] += 1; # next minute only
	foreach my $element (@_) {
		my ($value, $unit) = @$element;
		confess() unless(exists($absolute_prefixes{$unit}));
		$now[$absolute_prefixes{$unit}] = $value;
	}
	$now[4] += 1;
	my $seconds = timelocal(@now);
        return($seconds);
}


1;
