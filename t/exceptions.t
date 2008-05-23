use strict;
use warnings;
use Test::More tests => 6;
use Test::NoWarnings;
use DBI;
use DBIx::SchemaChecksum;

my $sc = DBIx::SchemaChecksum->new( dsn => "dbi:SQLite:dbname=t/dbs/base.db" );

eval { $sc->apply_sql_snippets };
like($@,qr/no current checksum/i,'apply_sql_snippets: no current checksum');

eval { $sc->get_checksums_from_snippet };
like($@,qr/need a filename/i,'get_checksums_from_snippet: no filename');

eval { $sc->get_checksums_from_snippet('/does/not/exist/I/hope') };
like($@,qr/cannot read /i,'get_checksums_from_snippet: bad filename');

{
    my ($pre,$post) = $sc->get_checksums_from_snippet('t/dbs/snippets/bad.t');
    is($pre,'1234567890123456789012345678901234567890','got pre');
    is($post,'','no post');
}

__END__

my $dump = $sc->schemadump;
like( $dump, qr/first_table/,                   'found table' );
like( $dump, qr/columns/,                       'found columns' );
like( $dump, qr/column_name.*?id/i,             'found column id' );
like( $dump, qr/column_name.*?a_column/i,       'found column a_column' );
like( $dump, qr/column_name.*?another_column/i, 'found column another_column' );

