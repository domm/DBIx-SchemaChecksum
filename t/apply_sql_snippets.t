use strict;
use warnings;
use Test::More tests => 4;
use Test::NoWarnings;
use DBIx::SchemaChecksum;
use File::Copy;
use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=t/dbs/update.db");

SKIP: {
    copy('t/dbs/update.tpl','t/dbs/update.db') || skip "cannot create test db",3;

    my $sc = DBIx::SchemaChecksum->new( dbh=>$dbh, no_prompt=>1 );

    my $pre_checksum = $sc->checksum;
    is ($pre_checksum,'d3c790b3634c0527494a9c42b02e8214b4cca656','checksum after two changes ok');

    $sc->build_update_path( 't/dbs/snippets' );
    eval { $sc->apply_sql_snippets($pre_checksum) };
    like($@,qr/^No update found/,'end of chain');

    my $post_checksum = $sc->checksum;
    is ($post_checksum,'d3c790b3634c0527494a9c42b02e8214b4cca656','checksum after two changes ok');

    copy('t/dbs/update.tpl','t/dbs/update.db') || die "cannot create test db: $!";
}

