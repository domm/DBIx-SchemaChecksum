use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my ($pre,$post) = $sc->get_checksums_from_snippet( 't/dbs/snippets/first_change.sql');
is($pre,'25a88a7fe53f646ffd399d91888a0b28098a41d1','preSHA1sum');
is($post,'056914cd5020547e62aebc320bb4128d8d277410','postSHA1sum');

done_testing();
