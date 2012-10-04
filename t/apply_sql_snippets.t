use strict;
use warnings;
use Test::Most;
use Test::Trap;
use DBIx::SchemaChecksum::App::ApplyChanges;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => MakeTmpDb->dsn,
    no_prompt=>1, sqlsnippetdir=> 't/dbs/snippets');

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'25a88a7fe53f646ffd399d91888a0b28098a41d1','checksum after two changes ok');

$sc->build_update_path;
trap { $sc->apply_sql_snippets($pre_checksum) };

is($trap->exit,0,'exit 0');
like($trap->stdout,qr/Apply first_change\.sql/,'Output: prompt for first_change.sql');
like($trap->stdout,qr/Apply another_change\.sql/,'Output: prompt for another_change.sql');
like($trap->stdout,qr/post checksum OK/,'Output: post checksum OK');
like($trap->stdout,qr/No update found that's based on/,'Output: end of tree');

my $post_checksum = $sc->checksum;
is ($post_checksum,'ddba663135de32f678d284a36a138e50e9b41515','checksum after two changes ok');

done_testing();

