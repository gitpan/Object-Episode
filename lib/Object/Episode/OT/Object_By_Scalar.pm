package Object::Episode::OT::Object_By_Scalar;
use strict;
use warnings;

#sub _lock { # no structure to lock
#}


sub new {
	my $class = shift;

	my $value = undef;
	my $self = \$value;
	bless($self, $class);
	$self->_init(@_) if ($self->can('_init'));
	return($self);
}


sub same {
	my $class = ref(shift);

	my $value = undef;
	my $self = \$value;
	bless($self, $class);
	$self->_init(@_) if ($self->can('_init'));
	return($self);
}


sub _init {  ${$_[0]} = $_[1] if (exists($_[1])); return; }
sub value { return(${$_[0]}); }
sub set { ${$_[0]} = $_[1]; return; };
sub is_WNT { return(${$_[0]} == $_[1]); };
sub is_WST { return(${$_[0]} eq $_[1]); };
sub equals { return(${$_[0]} == ${$_[1]}); };


sub prototype {
	my $class = shift;

	my $value = undef;
	my $self = \$value;
	bless($self, $class);
	return($self);
}


sub clone {
	my $self = shift;

	my $value = scalar($$self);
	my $clon = \$value;
	bless($clon, ref($self));
	return($clon);
}


1;