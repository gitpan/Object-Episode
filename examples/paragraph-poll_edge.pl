#! /usr/bin/perl -W
use strict;
use warnings;

use Object::Episode;
use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Flatened', 'FOR_ANY', 'IS_', 
                'TRUE' => 1,
                'FALSE' => 0,
                );
};
use Object::Episode::Paragraph::Poll_Edge;

my $loop = Object::Episode::Loop->new();
my $event_demo = Event_Demo2->new($loop->control);

my $file_test = sub { return((-e '/tmp/exists.txt') ? IS_TRUE : IS_FALSE); };
my $file_stat = sub { 
	return('') unless(-e '/tmp/exists.txt');
	return(join(' ', stat('/tmp/exists.txt'))); 
};
Object::Episode::Paragraph::Poll_Edge->
	new($event_demo, '_file_exists', $file_stat, 1);

$loop->run();

exit(0);

BEGIN {
package Event_Demo2;
use POSIX qw();

sub new	{ bless($_[1], $_[0]); }

sub evt_poll_edge_file_exists {
	print STDERR "poll edge: $_[1]\n";
}
}
