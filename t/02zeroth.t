use Test::More tests => 6;
BEGIN { use_ok('JSON::Path') };

use JSON;
my $object = {
	'foo' => [
		{
			'bar' => 1,
		},
		{
			'bar' => 2,
		},
		{
			'bar' => 3,
		},
	]
};

my $jpath1 = JSON::Path->new('$.foo[0]');
my @values1 = $jpath1->values(to_json($object));
is(scalar @values1, 1, 'Only returned a single result.');

my $jpath2 = JSON::Path->new('$.foo[0,1]');
my @values2 = $jpath2->values(to_json($object));
is(scalar @values2, 2, 'Returned two results.');

my $jpath3 = JSON::Path->new('$.foo[1:3]');
my @values3 = $jpath3->values(to_json($object));
is(scalar @values3, 2, 'Returned two results.');

my $jpath4 = JSON::Path->new('$.foo[-1:]');
my @values4 = $jpath4->values(to_json($object));
is(scalar @values4, 1, 'Returned one result.');
is($values4[0]->{bar}, 3, 'Correct result.');
