package DBIx::SchemaChecksum::App;
use 5.010;
use MooseX::App qw(Config);
extends qw(DBIx::SchemaChecksum);

use DBI;

option 'dsn'      => ( isa => 'Str', is => 'ro', required=>1, documentation=>q[DBI Data Source Name] );
option 'user'     => ( isa => 'Str', is => 'ro', documentation=>q[username to connect to database] );
option 'password' => ( isa => 'Str', is => 'ro', documentation=>q[password to connect to database] );
option '+catalog' => ( documentation => q[might be required by some DBI drivers]);
option '+schemata' => ( documentation => q[List of schematas to include in checksum] );
option '+tabletype' => ( documentation => q[table type according to DBI->table_info] );

has '+dbh' => (lazy_build=>1);
sub _build_dbh {
    my $self = shift;
    return DBI->connect( $self->dsn, $self->user, $self->password,
        { RaiseError => 1 } # TODO: set dbi->connect opts via App
    );
}

has 'scs' => (is=>'ro',isa=>'DBIx::SchemaChecksum', lazy_build=>1);
sub _build_scs {
    my $self = shift;
    my %opts = (
        dbh => $self->dbh,
    );

    foreach my $attr (qw(catalog schemata tabletype)) {
        if ($self->$attr) {
            $opts{$attr} = $self->$attr;
        }
    }

    return DBIx::SchemaChecksum->new( %opts );
}

1;
