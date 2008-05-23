use strict;
use warnings;
use Test::More tests => 7;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db" );

my $update = $sc->build_update_path( 't/dbs/snippets' );
is(int keys %$update,2,'2 updates');
is($update->{'89049e457886a86886a4fdf1f905b69250a8236c'}->[1],'d9a02517255045167053ea92dace728e1389f8ca','first sum link');
is($update->{'d9a02517255045167053ea92dace728e1389f8ca'}->[1],'7a1263a17bc9648e06de64fabb688633feb04f05','second sum link');
is($update->{'7a1263a17bc9648e06de64fabb688633feb04f05'},undef,'end of chain');

is($update->{'89049e457886a86886a4fdf1f905b69250a8236c'}->[0],'t/dbs/snippets/first_change.sql','first snippet');
is($update->{'d9a02517255045167053ea92dace728e1389f8ca'}->[0],'t/dbs/snippets/another_change.sql','second snippet');


