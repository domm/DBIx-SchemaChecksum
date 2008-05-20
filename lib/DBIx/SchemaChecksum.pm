package DBIx::SchemaChecksum;

use Moose;
use version; our $VERSION = version->new('0.01');

use DBI;
use Digest::SHA1;
use Data::Dumper;

has 'dbh' => ( isa => 'DBI::db', is => 'ro', required => 1 );
has 'catalog' => (is => 'ro', isa=>'Str',default=>'%');
has 'schemata' =>
  ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { ['%'] } );
has 'tabletype' => (is => 'ro', isa=>'Str',default=>'table');

has '_schemadump'     => ( is => 'rw', isa => 'Str' );
has '_got_schemadump' => ( is => 'rw', isa => 'Bool' );

=head1 NAME

DBIx::SchemaChecksum - Generate and compare checksums of database schematas

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS 

=cut

=head3 calculate_checksum

    my $checksum = $sc->calculate_checksum;

Return the checksum (as a SHA1 digest)

=cut

sub calculate_checksum {
    my $self = shift;

    my $as_string = $self->schemadump;

}

=head3 schemadump

    my $schemadump = $self->schemadump;

Returns a string representation of the whole schema (as a Data::Dumper 
Dump).

=cut

sub schemadump {
    my $self = shift;
    return $self->_schemadump if $self->_got_schemadump;

    my $tabletype = $self->tabletype;
    my $catalog = $self->catalog;

    my $dbh = $self->dbh;

    my %relevants = ();
    foreach my $schema (@{$self->schemata}) {
        foreach my $table ( $dbh->tables( $catalog, $schema, '%', $tabletype ) ) {
            my %data = ( table => $table );

            my $t = $table;
            $t =~ s/^.*?\.//;

            my @fks = $dbh->primary_key( $catalog, $schema, $t );
            $data{primary_keys} = \@fks;

            # columns
            my $sth1 = $dbh->column_info( $catalog, $schema, $t, '%' );
            if ($sth1) {
                $data{columns} = $sth1->fetchall_arrayref(
                {
                    map { $_ => 1 }
                      qw(COLUMN_NAME COLUMN_SIZE NULLABLE COLUMN_DEF ORDINAL_POSITION TYPE_NAME)
                }
            );
            }

            # foreign keys
            my $sth2 = $dbh->foreign_key_info( '', '', '', '', $schema, $t );
            if ($sth2) {
                $data{foreign_keys} = $sth2->fetchall_arrayref(
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
    return scalar $dumper->Dump;


    return $self->_schemadump('foo');

}


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

## Please see file perltidy.ERR
