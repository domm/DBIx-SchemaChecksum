use strict;
use warnings;
use Test::More tests => 7;
use Test::NoWarnings;
use Test::Deep;
use DBI;
use DBIx::SchemaChecksum;
use File::Spec;

my $sc =
  DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db" );

my $update = $sc->build_update_path('t/dbs/snippets2');
is( int keys %$update, 3, '3 updates' );
is(
    $update->{'d3c790b3634c0527494a9c42b02e8214b4cca656'}->[1],
    '2becef8911e9ece65b74ae0c510f8b67780ec656',
    'first sum link'
);
is(
    $update->{'2becef8911e9ece65b74ae0c510f8b67780ec656'}->[0],
    'SAME_CHECKSUM','same_checksum');
is(
    $update->{'2becef8911e9ece65b74ae0c510f8b67780ec656'}->[2],'2becef8911e9ece65b74ae0c510f8b67780ec656','has same checksum');
is(
    $update->{'2becef8911e9ece65b74ae0c510f8b67780ec656'}->[4],'d1ed5de12cf82a688959d5b5ca05ece7f0e316ff','second sum link'
);
is( $update->{'75c04e839dfe8e58303d2aaa4673833edc126152'},
    undef, 'end of chain' );



