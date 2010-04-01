#! /usr/bin/perl -W
use strict;
use warnings;
use Carp;

package Event_Demo4;
use POSIX qw();
use Data::Dumper;
use Object::Episode;
use Package::Transporter sub{eval shift}, 'mix_in:Object::Episode';
use Object::Episode::Paragraph::TCP_Socket_IO;

sub new	{ 
	my $class = shift;

	my $self = [undef, @_];
	bless($self, $class);

	my $socket = $self->connect();
	$self->[0] = Object::Episode::Paragraph::TCP_Socket_IO->new($self, $socket, 10);
}


sub connect {
        my ($self, $address) = @_;

	use IO::Socket::INET;
	my $socket = IO::Socket::INET->new(
		'Proto' => 'tcp',
		'PeerAddr' => '127.0.0.1:11010',
		'Blocking' => IS_FALSE,
                )
		|| Carp::confess("$0: IO::Socket::INET: $address: $!");
	unless ($socket->connected()) {
		Carp::confess("$0: IO::Socket::INET: $address: $!");
        }
        return() unless (defined($socket) and ref($socket));

        $socket->autoflush(1);
        return($socket);
}


sub evt_tcp_socket_io_arrived {
	print STDERR "evt_tcp_socket_io_arrived, current buffer: ", ${$_[1]}, "\n";
	if(${$_[1]} =~ m,POP3,) {
		$_[0][0]->add_to_outbuffer(\qq{quit\r\n});
	}
}

sub evt_tcp_socket_io_departed {
	print STDERR "evt_tcp_socket_io_departed, status now '$_[1]'.\n";
}


sub evt_tcp_socket_io_drop {
	print STDERR "evt_tcp_socket_io_drop\n";
	${$_[0][1]} = 0;
}


package main;

use Object::Episode;
use Package::Transporter sub{eval shift}, 'mix_in:Object::Episode';

my $loop = Object::Episode::Loop->new();
my $event_demo = Event_Demo4->new($loop->control);
$loop->run();

exit(0);
