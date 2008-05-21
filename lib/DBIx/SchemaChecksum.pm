package DBIx::SchemaChecksum;

use Moose;
use version; our $VERSION = version->new('0.02');

use DBI;
use Digest::SHA1;
use Data::Dumper;

with 'MooseX::Getopt';

has 'dsn' => ( isa => 'Str', is => 'ro', required => 1 );
has 'user'     => ( isa => 'Str', is => 'ro' );
has 'password' => ( isa => 'Str', is => 'ro' );

has 'catalog' => ( is => 'ro', isa => 'Str', default => '%' );
has 'schemata' =>
  ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { ['%'] } );
has 'tabletype' => ( is => 'ro', isa => 'Str', default => 'table' );

has 'verbose' => ( is => 'ro', isa => 'Bool', default => 0 );

has '_dbh'        => ( isa => 'DBI::db', is  => 'rw' );
has '_schemadump' => ( is  => 'rw',      isa => 'Str' );

=head1 NAME

DBIx::SchemaChecksum - Generate and compare checksums of database schematas

=head1 SYNOPSIS

    my $sc = DBIx::SchemaChecksum->new( dsn => 'dbi:Pg:name=foo' );
    print $sc->checksum;

=head1 DESCRIPTION

When you're dealing with several instances of the same database (eg.  
developer, testing, stage, production), it is crucial to make sure 
that all databases use the same schema. This can be quite an 
hair-pulling experience, and this module should help you keep your 
hair (if you're already bald, it won't make your hair grow back, 
sorry...)

DBIx::SchemaChecksum connects to your database, gets schema 
information (tables, columns, primary keys, foreign keys) and 
generates a SHA1 digest. This digest can then be used to easily verify schema consistency across different databases.

B<Caveat:> The same schema might produce different checksums on 
different database versions.

DBIx::SchemaChecksum works with PostgreSQL 8.3 and SQLite (but see 
below). I assume that thanks to the abstraction provided by the C<DBI> 
it works with most databases. If you try DBIx::SchemaChecksum with 
different database systems, I'd love to hear some feedback...

=head2 SQLite and column_info

DBD::SQLite doesn't really implement C<column_info>, which is needed 
to generate the checksum. We use the monkey-patch included in
http://rt.cpan.org/Public/Bug/Display.html?id=13631 
to make it work

=head2 Scripts

Please take a look at the scripts included in this distribution:

=head3 schema_checksum.pl

Calculates the checksum and prints it to STDOUT

=head1 METHODS 

=head2 Public Methods

=cut

=head3 BUILD

Moose Object Builder which sets up the DB connection.

=cut

sub BUILD {
    my $self = shift;
    my $dbh = DBI->connect( $self->dsn, $self->user, $self->password )
      || die "Cannot connect to database: " . $DBI::errstr;
    $self->_dbh($dbh);
}

=head3 checksum

    my $checksum = $sc->checksum;

Return the checksum (as a SHA1 digest)

=cut

sub checksum {
    my $self = shift;

    my $as_string = $self->schemadump;
    return Digest::SHA1::sha1_hex($as_string);
}

=head3 schemadump

    my $schemadump = $self->schemadump;

Returns a string representation of the whole schema (as a Data::Dumper 
Dump).

=cut

sub schemadump {
    my $self = shift;

    return $self->_schemadump if $self->_schemadump;

    my $tabletype = $self->tabletype;
    my $catalog   = $self->catalog;

    my $dbh = $self->_dbh;

    my %relevants = ();
    foreach my $schema ( @{ $self->schemata } ) {
        foreach my $table ( $dbh->tables( $catalog, $schema, '%', $tabletype ) )
        {
            my %data = ( table => $table );

            # remove schema name from table
            my $t = $table;
            $t =~ s/^.*?\.//;

            my @pks = $dbh->primary_key( $catalog, $schema, $t );
            $data{primary_keys} = \@pks if @pks;

            # columns
            my $sth_col = $dbh->column_info( $catalog, $schema, $t, '%' );
            $data{columns} = $sth_col->fetchall_arrayref(
                {
                    map { $_ => 1 }
                      qw(COLUMN_NAME COLUMN_SIZE NULLABLE ORDINAL_POSITION TYPE_NAME COLUMN_DEF)
                }
            );

            # foreign keys
            my $sth_fk =
              $dbh->foreign_key_info( '', '', '', $catalog, $schema, $t );
            if ($sth_fk) {
                $data{foreign_keys} = $sth_fk->fetchall_arrayref(
                    {
                        map { $_ => 1 }
                          qw(FK_NAME UK_NAME UK_COLUMN_NAME FK_TABLE_NAME FK_COLUMN_NAME UPDATE_RULE DELETE_RULE DEFERRABILITY)
                    }
                );
            }

            $relevants{$table} = \%data;
        }

    }
    my $dumper = Data::Dumper->new( [ \%relevants ] );
    $dumper->Sortkeys(1);

    return $self->_schemadump( scalar $dumper->Dump );
}

# sqlite column_info monkeypatch
# see http://rt.cpan.org/Public/Bug/Display.html?id=13631
BEGIN {
    *DBD::SQLite::db::column_info = \&_sqlite_column_info;
}

sub _sqlite_column_info {
    my ( $dbh, $catalog, $schema, $table, $column ) = @_;

    $table =~ s/["']//g;
    $column = undef
      if defined $column && $column eq '%';

    my $sth_columns = $dbh->prepare(qq{PRAGMA table_info('$table')});
    $sth_columns->execute;

    my @names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
      DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH
      DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE
      REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB
      CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
    );

    my @cols;
    while ( my $col_info = $sth_columns->fetchrow_hashref ) {
        next if defined $column && $column ne $col_info->{name};

        my %col;

        $col{TABLE_NAME}  = $table;
        $col{COLUMN_NAME} = $col_info->{name};

        my $type = $col_info->{type};
        if ( $type =~ s/(\w+)\((\d+)(?:,(\d+))?\)/$1/ ) {
            $col{COLUMN_SIZE}    = $2;
            $col{DECIMAL_DIGITS} = $3;
        }

        $col{TYPE_NAME} = $type;

        $col{COLUMN_DEF} = $col_info->{dflt_value}
          if defined $col_info->{dflt_value};

        if ( $col_info->{notnull} ) {
            $col{NULLABLE}    = 0;
            $col{IS_NULLABLE} = 'NO';
        }
        else {
            $col{NULLABLE}    = 1;
            $col{IS_NULLABLE} = 'YES';
        }

        for my $key (@names) {
            $col{$key} = undef
              unless exists $col{$key};
        }

        push @cols, \%col;
    }

    my $sponge = DBI->connect( "DBI:Sponge:", '', '' )
      or return $dbh->DBI::set_err( $DBI::err, "DBI::Sponge: $DBI::errstr" );
    my $sth = $sponge->prepare(
        "column_info $table",
        {
            rows          => [ map { [ @{$_}{@names} ] } @cols ],
            NUM_OF_FIELDS => scalar @names,
            NAME          => \@names,
        }
    ) or return $dbh->DBI::set_err( $sponge->err(), $sponge->errstr() );
    return $sth;
}

=head2 Attributes generated by Moose

All of this methods can also be set from the commandline. See 
MooseX::Getopts.

=head3 dsn

The dsn. Required.

=head3 user

The user to use to connect to the DB.

=head3 password

The password to use to authenticate the user.

=head3 catalog

The database catalog searched for data. Not implemented by all DBs. See C<DBI::table_info>

Default C<%>.

=head3 schemata

An Arrayref containg names of schematas to include in checksum calculation. See C<DBI::table_info>

Default C<%>.

=head3 tabletype

What kind of tables to include in checksum calculation. See C<DBI::table_info>

Default C<table>.

=head3 verbose

Be verbose or not. Default: 0

=cut

q{ Favourite record of the moment: The Dynamics - Version Excursions }

__END__

=head1 AUTHOR

Thomas Klausner, C<< <domm at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-dbix-schemachecksum at rt.cpan.org>, or through
the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-SchemaChecksum>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::SchemaChecksum

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-SchemaChecksum>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-SchemaChecksum>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-SchemaChecksum>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-SchemaChecksum>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Klaus Ita and Armin Schreger for writing the core code. I 
just glued it together...

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, revdev.at, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
