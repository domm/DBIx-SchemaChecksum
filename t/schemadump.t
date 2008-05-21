use strict;
use warnings;
use Test::More tests => 6;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/base.db" );

my $dump = $sc->schemadump;
like( $dump, qr/first_table/,                   'found table' );
like( $dump, qr/columns/,                       'found columns' );
like( $dump, qr/column_name.*?id/i,             'found column id' );
like( $dump, qr/column_name.*?a_column/i,       'found column a_column' );
like( $dump, qr/column_name.*?another_column/i, 'found column another_column' );

