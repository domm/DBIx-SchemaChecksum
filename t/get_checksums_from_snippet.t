use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db" );


my ($pre,$post) = $sc->get_checksums_from_snippet( 't/dbs/snippets/first_change.sql');
is($pre,'89049e457886a86886a4fdf1f905b69250a8236c','preSHA1sum');
is($post,'d9a02517255045167053ea92dace728e1389f8ca','postSHA1sum');
