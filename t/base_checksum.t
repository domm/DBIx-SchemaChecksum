use strict;
use warnings;
use Test::More qw(no_plan);
use DBI;
use DBIx::SchemaChecksum;

my $dbh = DBI->connect("dbi:SQLite:dbname=t/dbs/base.db");

my $sc = DBIx::SchemaChecksum->new( dbh => $dbh );


TODO: {
    local $TODO= "calculate_checksum not implemented yet..";
    my $checksum = $sc->calculate_checksum; 
    is($checksum,'some_checksum','base checksum');
}
