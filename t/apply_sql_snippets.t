use strict;
use warnings;
use Test::More tests => 4;
use Test::NoWarnings;
use DBIx::SchemaChecksum;
use File::Copy;
copy('t/dbs/update.tpl','t/dbs/update.db') || die "cannot create test db: $!";

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db", no_prompt=>1 );

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'89049e457886a86886a4fdf1f905b69250a8236c','checksum after two changes ok');

$sc->build_update_path( 't/dbs/snippets' );
eval { $sc->apply_sql_snippets($pre_checksum) };
like($@,qr/^No update found/,'end of chain');

my $post_checksum = $sc->checksum;
is ($post_checksum,'7a1263a17bc9648e06de64fabb688633feb04f05','checksum after two changes ok');

copy('t/dbs/update.tpl','t/dbs/update.db') || die "cannot create test db: $!";
