use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use File::Copy;
use IO::Capture::Stdout;

SKIP: {
    copy('t/dbs/update.tpl','t/dbs/update.db') || skip "cannot create test db",3;

    my $sc = DBIx::SchemaChecksum->new( dbh => DBI->connect("dbi:SQLite:dbname=t/dbs/update.db"), show_update_path=>1 );
 #   my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/update.db", no_prompt=>1, show_update_path=>1 );
    is($sc->show_update_path,1,'show update path is set');

    my $pre_checksum = $sc->checksum;
    is ($pre_checksum,'25a88a7fe53f646ffd399d91888a0b28098a41d1','pre checksum');
    my $capture = IO::Capture::Stdout->new();
    $capture->start;
    $sc->build_update_path( 't/dbs/snippets2' );
    eval { $sc->apply_sql_snippets($pre_checksum); diag("xx") };
    $capture->stop;

    like($capture->read,qr/first_change/,'1st');
    like($capture->read,qr/second_change_no/,'2nd');
    like($capture->read,qr/second_change\.sql/,'2nd');
    like($capture->read,qr/third_change/,'4rd');

}

done_testing();
