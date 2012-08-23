package DBIx::SchemaChecksum::App;
use 5.010;
use MooseX::App qw(Config);
extends qw(DBIx::SchemaChecksum);

use DBI;

option 'dsn'      => ( isa => 'Str', is => 'ro', required=>1, documentation=>q[DBI Data Source Name] );
option 'user'     => ( isa => 'Str', is => 'ro', documentation=>q[username to connect to database] );
option 'password' => ( isa => 'Str', is => 'ro', documentation=>q[password to connect to database] );


1;
