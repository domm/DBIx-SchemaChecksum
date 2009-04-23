use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/base.db" );
my $sc2 = DBIx::SchemaChecksum->new( dbh => $sc->dbh );

my $checksum = $sc->checksum;
my $checksum2 = $sc2->checksum;

is( $checksum, '216c74385e1fc6ecb2ec65c792d0d243fdd795bd', 'base checksum' );
is( $checksum2, '216c74385e1fc6ecb2ec65c792d0d243fdd795bd', 'base checksum' );
