use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use File::Spec;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh );

my $update = $sc->build_update_path('t/dbs/snippets2');
is( int keys %$update, 3, '3 updates' );
is(
    $update->{'25a88a7fe53f646ffd399d91888a0b28098a41d1'}->[1],
    '056914cd5020547e62aebc320bb4128d8d277410',
    'first sum link'
);
is(
    $update->{'056914cd5020547e62aebc320bb4128d8d277410'}->[0],
    'SAME_CHECKSUM','same_checksum');
is(
    $update->{'056914cd5020547e62aebc320bb4128d8d277410'}->[2],'056914cd5020547e62aebc320bb4128d8d277410','has same checksum');
is(
    $update->{'056914cd5020547e62aebc320bb4128d8d277410'}->[4],'ddba663135de32f678d284a36a138e50e9b41515','second sum link'
);
is( $update->{'f8334e554fc5f7cac3ffda285a8ae8c876fa5956'},
    undef, 'end of chain' );


done_testing();
