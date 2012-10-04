use strict;
use warnings;
use Test::Most;
use lib qw(t);
use MakeTmpDb;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my $checksum = $sc->checksum;

is( $checksum, '25a88a7fe53f646ffd399d91888a0b28098a41d1', 'base checksum' );

done_testing();

