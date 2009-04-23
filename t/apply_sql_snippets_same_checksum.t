use strict;
use warnings;
use Test::More tests => 4;
use Test::NoWarnings;
use DBIx::SchemaChecksum;
use File::Copy;


SKIP: {
    copy('t/dbs/update.tpl','t/dbs/update.db') || skip "cannot create test db",3;

    my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db", no_prompt=>1 );

    my $pre_checksum = $sc->checksum;
    is ($pre_checksum,'216c74385e1fc6ecb2ec65c792d0d243fdd795bd','pre checksum');

    $sc->build_update_path( 't/dbs/snippets2' );
    eval { $sc->apply_sql_snippets($pre_checksum) };
    like($@,qr/^No update found/,'end of chain');

    my $post_checksum = $sc->checksum;
    is ($post_checksum,'216c74385e1fc6ecb2ec65c792d0d243fdd795bd','checksum after two changes ok');

    copy('t/dbs/update.tpl','t/dbs/update.db') || die "cannot create test db: $!";
}

