use strict;
use warnings;
use Test::Most;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dbh =>DBI->connect("dbi:SQLite:dbname=t/dbs/base.db"));

# TODO moved to different class. check after refctoring if and where we need this test
#eval { $sc->apply_sql_snippets };
#like($@,qr/no current checksum/i,'apply_sql_snippets: no current checksum');

eval { $sc->get_checksums_from_snippet };
like($@,qr/need a filename/i,'get_checksums_from_snippet: no filename');

eval { $sc->get_checksums_from_snippet('/does/not/exist/I/hope') };
like($@,qr/cannot read /i,'get_checksums_from_snippet: bad filename');

{
    my ($pre,$post) = $sc->get_checksums_from_snippet('t/dbs/snippets/bad.foo');
    is($pre,'1234567890123456789012345678901234567890','got pre');
    is($post,'','no post');
}

done_testing();

