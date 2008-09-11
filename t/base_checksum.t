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

is( $checksum, '5f22e538285f79ec558e16dbfeb0b34a36e4da19', 'base checksum' );
is( $checksum2, '5f22e538285f79ec558e16dbfeb0b34a36e4da19', 'base checksum' );
