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
    $update->{'5f22e538285f79ec558e16dbfeb0b34a36e4da19'}->[1],
    '6620c14bb4aaafdcf142022b5cef7f74ee7c7383',
    'first sum link'
);
is(
    $update->{'6620c14bb4aaafdcf142022b5cef7f74ee7c7383'}->[0],
    'SAME_CHECKSUM','same_checksum');
is(
    $update->{'6620c14bb4aaafdcf142022b5cef7f74ee7c7383'}->[2],'6620c14bb4aaafdcf142022b5cef7f74ee7c7383','has same checksum');
is(
    $update->{'6620c14bb4aaafdcf142022b5cef7f74ee7c7383'}->[4],'39219d6fd802540c79b0a93d7111ea45f66e9518','second sum link'
);
is( $update->{'7a1263a17bc9648e06de64fabb688633feb04f05'},
    undef, 'end of chain' );



