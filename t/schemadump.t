use strict;
use warnings;
use Test::More qw(no_plan);
use DBI;
use DBIx::SchemaChecksum;


my $dbh = DBI->connect("dbi:SQLite:dbname=t/dbs/base.db");
#my $dbh = DBI->connect("dbi:Pg:dbname=babilu");

my $sc = DBIx::SchemaChecksum->new( dbh => $dbh );
TODO: {
    local $TODO="sqlite has no proper metadata info, so I cant use it for testing...";

    is($sc->schemadump,'foo');
}
