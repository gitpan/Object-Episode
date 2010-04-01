package Object::Episode;
use strict;
use warnings;

our $VERSION = '0.01';

#$Package::Transporter::Package::DEBUG = 1;

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Flatened', 'FOR_BRANCH', 'IS_', 
                'TRUE' => 1,
                'FALSE' => 0,
                );
};

1;
