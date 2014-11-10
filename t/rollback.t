use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum::App::ApplyChanges;
use lib qw(t);
use MakeTmpDb;
use DBD::SQLite 1.35;

my $sc = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => MakeTmpDb->dsn,
    no_prompt=>1, sqlsnippetdir=> 't/dbs/snippets_rollback');

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'660d1e9b6aec2ac84c2ff6b1acb5fe3450fdd013','checksum after two changes ok');

trap { $sc->run };

like($trap->stdout,qr/Apply first_change\.sql/,'Output: prompt for first_change.sql');
like($trap->stdout,qr/Apply another_change\.sql/,'Output: prompt for another_change.sql');
like($trap->stderr,qr/syntax error/,'another_change.sql syntex error');

my $post_checksum = $sc->checksum;
is ($post_checksum,'e63a31c18566148984a317006dad897b75d8bdbe','checksum of first change after sql syntax error in second sql');

done_testing();

