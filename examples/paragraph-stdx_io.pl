#! /usr/bin/perl -W
use strict;
use warnings;

#this script requires a 'stty cbreak;' on the TTY

package Event_Demo3;
use POSIX qw();
use Data::Dumper;

sub new	{ 
	my $class = shift;

	my $self = [undef, @_];
	bless($self, $class);
	$self->[0] = Object::Episode::Paragraph::STDx_IO->new($self, 6);
}

sub evt_stdx_io_arrived {
	print STDERR "evt_stdx_io_arrived, current buffer: ", ${$_[1]}, "\n";
	if(${$_[1]} eq 'asdf') {
		$_[0][0]->add_to_outbuffer(\qq{Heya!\n});
	}
}

sub evt_stdx_io_departed {
	print STDERR "evt_stdx_io_departed, status now '$_[1]'.\n";
}


sub evt_stdx_io_drop {
	print STDERR "evt_stdx_io_drop\n";
	${$_[0][1]} = 0;
}


package main;

use Object::Episode;
use Package::Transporter sub{eval shift};
use Object::Episode::Paragraph::STDx_IO;

my $loop = Object::Episode::Loop->new();
my $event_demo = Event_Demo3->new($loop->control);
$loop->run();

exit(0);
