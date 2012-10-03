use strict;
use warnings;
use Test::Most;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dbh => DBI->connect("dbi:SQLite:dbname=t/dbs/base.db") );

my $checksum = $sc->checksum;

is( $checksum, '25a88a7fe53f646ffd399d91888a0b28098a41d1', 'base checksum' );

done_testing();

