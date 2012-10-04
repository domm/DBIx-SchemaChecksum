use strict;
use warnings;
use Test::Most;
use DBIx::SchemaChecksum;
use DBIx::SchemaChecksum::App::ApplyChanges;
use lib qw(t);
use MakeTmpDb;

my $sc = DBIx::SchemaChecksum::App::ApplyChanges->new(
    dsn => MakeTmpDb->dsn,
    no_prompt=>1, sqlsnippetdir=> 't/dbs/snippets');

my $pre_checksum = $sc->checksum;
is ($pre_checksum,'25a88a7fe53f646ffd399d91888a0b28098a41d1','checksum after two changes ok');

$sc->build_update_path;
eval { $sc->apply_sql_snippets($pre_checksum) };
like($@,qr/^No update found/,'end of chain');

my $post_checksum = $sc->checksum;
is ($post_checksum,'ddba663135de32f678d284a36a138e50e9b41515','checksum after two changes ok');

done_testing();

