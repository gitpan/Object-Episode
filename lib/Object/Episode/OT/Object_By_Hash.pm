package Object::Episode::OT::Object_By_Hash;
use strict;
use warnings;
#use Hash::Util;


sub _lock { # locks the structure (set of existing keys)
#	Hash::Util::lock_keys(%$self);
	Internals::hv_clear_placeholders(%{$_[0]});
	Internals::SvREADONLY(%{$_[0]}, 1);
	return;
}


sub new {
	my $class = shift;

	my $self = {};
	bless($self, $class);
	$self->_init(@_) if ($self->can('_init'));
	$self->_lock();

	return($self);
}


sub same {
	my $class = ref(shift);

	my $self = {};
	bless($self, $class);
	$self->_init(@_) if ($self->can('_init'));
	$self->_lock();

	return($self);
}


sub prototype {
	my $class = shift;

	my $self = {};
	bless($self, $class);
	return($self);
}


sub clone {
	my $self = shift;

	my $clon = {%$self};
	bless($clon, ref($self));
	$clon->_lock();

	return($clon);
}


sub _generic_accessor {
	return(($#_ == 1) ? $_[0]{$_[1]} : ($_[0]{$_[1]} = $_[2]));
};


1;