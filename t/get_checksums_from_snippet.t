use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db" );


my ($pre,$post) = $sc->get_checksums_from_snippet( 't/dbs/snippets/first_change.sql');
is($pre,'5f22e538285f79ec558e16dbfeb0b34a36e4da19','preSHA1sum');
is($post,'6620c14bb4aaafdcf142022b5cef7f74ee7c7383','postSHA1sum');
