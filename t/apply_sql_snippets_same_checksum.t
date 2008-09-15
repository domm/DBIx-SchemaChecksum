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
    is ($pre_checksum,'5f22e538285f79ec558e16dbfeb0b34a36e4da19','pre checksum');

    $sc->build_update_path( 't/dbs/snippets2' );
    eval { $sc->apply_sql_snippets($pre_checksum) };
    like($@,qr/^No update found/,'end of chain');

    my $post_checksum = $sc->checksum;
    is ($post_checksum,'1f7d99966e7855a739d8aa1e7431b7506be659f6','checksum after two changes ok');

    copy('t/dbs/update.tpl','t/dbs/update.db') || die "cannot create test db: $!";
}

