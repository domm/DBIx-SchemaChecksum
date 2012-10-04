use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use File::Spec;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum->new( dbh => MakeTmpDb->dbh, sqlsnippetdir=>'t/dbs/snippets' );

my $update = $sc->_update_path;
is( int keys %$update, 2, '2 updates' );
is(
    $update->{'25a88a7fe53f646ffd399d91888a0b28098a41d1'}->[1],
    '056914cd5020547e62aebc320bb4128d8d277410',
    'first sum link'
);
is(
    $update->{'056914cd5020547e62aebc320bb4128d8d277410'}->[1],
    'ddba663135de32f678d284a36a138e50e9b41515',
    'second sum link'
);
is( $update->{'ddba663135de32f678d284a36a138e50e9b41515'},
    undef, 'end of chain' );

cmp_deeply(
    [File::Spec->splitdir($update->{'25a88a7fe53f646ffd399d91888a0b28098a41d1'}->[0])],
    [qw(t dbs snippets first_change.sql)],
    'first snippet'
);
cmp_deeply(
    [File::Spec->splitdir($update->{'056914cd5020547e62aebc320bb4128d8d277410'}->[0])],
    [qw(t dbs snippets another_change.sql)],
    'second snippet'
);

# corner cases
my $sc2 = DBIx::SchemaChecksum->new(
    dbh => MakeTmpDb->dbh,
    sqlsnippetdir => 't/dbs/no_snippets',
);
eval {
    $sc2->_update_path;
};
like($@,qr/Attribute \(_update_path\) .* value undef/,'no snippets found, so update_path is empty');

eval {
    my $sc3 = DBIx::SchemaChecksum->new(
        dbh => MakeTmpDb->dbh,
        sqlsnippetdir => 't/no_snippts_here',
    );
    $sc3->_update_path;
};
like($@,qr/Cannot find sqlsnippetdir/i,'no snippet dir');

eval {
    my $sc4 = DBIx::SchemaChecksum->new(
        dbh => MakeTmpDb->dbh,
        sqlsnippetdir => 't/build_update_path.t',
    );
    $sc4->_update_path;
};
like($@,qr/cannot find sqlsnippetdir/i,'no snippet dir');

done_testing();

