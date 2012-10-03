use strict;
use warnings;
use Test::Most;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dbh => DBI->connect("dbi:SQLite:dbname=t/dbs/update.db" ));

my $dump = $sc->schemadump;
like( $dump, qr/first_table/,                   'found table' );
like( $dump, qr/columns/,                       'found columns' );
like( $dump, qr/column_name.*?id/i,             'found column id' );
like( $dump, qr/column_name.*?a_column/i,       'found column a_column' );
like( $dump, qr/column_name.*?another_column/i, 'found column another_column' );

done_testing();

