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

is( $checksum, 'd3c790b3634c0527494a9c42b02e8214b4cca656', 'base checksum' );
is( $checksum2, 'd3c790b3634c0527494a9c42b02e8214b4cca656', 'base checksum' );
