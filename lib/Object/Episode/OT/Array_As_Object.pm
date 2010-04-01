package Object::Episode::OT::Array_As_Object;
use strict;
use warnings;

use Package::Transporter sub{eval shift}, sub {
	$_[0]->register_drain('::Flatened', 'FOR_FAMILY', 'IDX_', 
                'NO_ELEMENTS' => -1,
                'LAST_ELEMENT' => -1, # Again? Well, what can you say...
                );
};

sub new {
	my $class = shift;

	my $self = [];
	bless($self, $class);
	push(@$self, @{$_[0]}) if (exists($_[0]));

	return($self);
}


sub lock { Internals::SvREADONLY(@{$_[0]}, 1); return; };
sub unlock { Internals::SvREADONLY(@{$_[0]}, 0); return; };

sub set_size { $#{$_[0]} = $_[1]-1; return; };

sub as_list { return(@{$_[0]}); };

sub element_at { exists($_[0][$_[1]]) ? $_[0][$_[1]] : undef; };
sub elements_at { my @r = (); push(@r, $_[0][$_]) for @_; return(@r); };
sub element_count { return($#{$_[0]} +1); };

sub first_element { exists($_[0][0]) ? $_[0][0] : undef; };
sub last_element { exists($_[0][-1]) ? $_[0][-1] : undef; };

sub splice_wrap_0arg { splice(@{shift()}); };
sub splice_wrap_1arg { splice(@{shift()}, shift()); };
sub splice_wrap_2arg { splice(@{shift()}, shift(), shift()); };
sub splice_wrap_3arg { splice(@{shift()}, shift(), shift(), @_); };

sub insert_at { splice(@{shift()}, shift(), 0, @_); };

sub push_wrap { push(@{shift()}, @_); };
sub pop_wrap { pop(@{$_[0]}); };
sub unshift_wrap { unshift(@{shift()}, @_); };
sub shift_wrap { shift(@{$_[0]}); };


sub last_index { $#{$_[0]}; }
sub has_elements { ($#{$_[0]} > IDX_NO_ELEMENTS); }
sub has_no_elements { ($#{$_[0]} == IDX_NO_ELEMENTS); }

sub first_defined_element { defined($_) && return($_) for @{$_[0]}; return; };
sub defined_elements { grep(defined($_), @{$_[0]}); };

sub first_nonempty_element { length($_) && return($_) for @{$_[0]}; return; };
sub nonempty_elements { grep(length($_), @{$_[0]}); };

sub method_on_elements {
    my ($self, $method) = (shift, shift);

    $_->$method(@_) foreach (@$self);
    return;
}

sub remove_undefined_at_end {
	my $self = shift;

	while (($#$self > IDX_NO_ELEMENTS) and
	    not defined($self->[IDX_LAST_ELEMENT])) {
		pop(@$self);
	}
	return;
}

sub contains_WNT { ($_ == $_[1]) && return(IS_TRUE) for @{$_[0]}; return(IS_FALSE); }
sub contains_WST { ($_ eq $_[1]) && return(IS_TRUE) for @{$_[0]}; return(IS_FALSE); }

sub index_of_WNT {
	my $i = IDX_NO_ELEMENTS;
	foreach (@{$_[0]}) {
		$i += 1;
		return($i) if ($_[1] == $_);
	}
	return(IDX_NO_ELEMENTS);
};

sub index_of_nearest_lower_element_WNT {
	my $i = IDX_NO_ELEMENTS;
	foreach (@{$_[0]}) {
		$i += 1;
		return($i) if ($_[1] < $_);
	}
	return($i+1);
};

sub push_if_distinct_WNT {
	push(@{$_[0]}, grep(! $_[0]->contains_WNT($_), @{$_[1]}));
	return; 
}

sub insert_sorted_WNT {
	splice(@{$_[0]}, index_of_nearest_lower_element_WNT(@_), 0, $_[1]);
	return; 
}

sub remove_undefined {
	@{$_[0]} = (grep(defined($_), @{$_[0]}));
	return; 
};

sub remove_element_WNT ($$) {
	@{$_[0]} = (grep((defined($_) and ($_ != $_[1])), splice(@{$_[0]})));
	return; 
}

sub remove_element_WST ($$) {
	@{$_[0]} = (grep((defined($_) and ($_ ne $_[1])), splice(@{$_[0]})));
	return; 
}


sub rotate_elements_left { push(@{$_[0]}, shift(@{$_[0]})) if ($#{$_[0]} > 0); }
sub rotate_elements_right { unshift(@{$_[0]}, pop(@{$_[0]})) if ($#{$_[0]} > 0); }


sub maximum_WNT {
	my $self = shift;

	return(undef) if ($#{$_[0]} == IDX_NO_ELEMENTS);

	my $max = $_[0][0];
	foreach (@{$_[0]}) {
	    $max = $_ if ($_ > $max);
	}
	return($max);
}


sub minimum_WNT {
	my $self = shift;

	return(undef) if ($#{$_[0]} == IDX_NO_ELEMENTS);

	my $min = $_[0][0];
	foreach (@{$_[0]}) {
	    $min = $_ if ($_ < $min);
	}
	return($min);
}


sub has_duplicates {
	my $elements = {};
	foreach my $element (@{$_[0]}) {
		return(IS_TRUE) if (exists($elements->{$element}));
		$elements->{$element} = undef;
	}
	return(IS_FALSE);
}

1;
