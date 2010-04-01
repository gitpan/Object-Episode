use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Object::Episode',
	'VERSION_FROM'	=> 'lib/Object/Episode.pm',
	'AUTHOR'	=> 'Winfried Trumper <pub+perl@wt.tuxomania.net>',
	'LICENSE'	=> 'perl',
	'PREREQ_PM'	  => { 
		'parent' => 0.01,
		'Test::Simple' => 0.01,
	},
);
