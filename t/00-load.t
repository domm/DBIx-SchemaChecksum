#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::SchemaChecksum' );
}

diag( "Testing DBIx::SchemaChecksum $DBIx::SchemaChecksum::VERSION, Perl $], $^X" );
