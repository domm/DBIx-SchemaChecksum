use strict;
use warnings;
use Test::More tests => 2;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/base.db" );

my $checksum = $sc->checksum;
is( $checksum, '89049e457886a86886a4fdf1f905b69250a8236c', 'base checksum' );
