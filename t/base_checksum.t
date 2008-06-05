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

is( $checksum, '89049e457886a86886a4fdf1f905b69250a8236c', 'base checksum' );
is( $checksum2, '89049e457886a86886a4fdf1f905b69250a8236c', 'base checksum' );