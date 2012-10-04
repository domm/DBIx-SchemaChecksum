package DBIx::SchemaChecksum;

use 5.010;
use Moose;
use version; our $VERSION = version->new('0.28');

use DBI;
use Digest::SHA1;
use Data::Dumper;
use Path::Class;
use Carp;
use File::Find::Rule;
with  'MooseX::Getopt';

has 'dbh' => ( is => 'ro', required=>1 );

has 'catalog' => (
    is => 'ro',
    isa => 'Str',
    default => '%',
    documentation => q[might be required by some DBI drivers]
);

has 'schemata' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { ['%'] },
    documentation => q[List of schematas to include in checksum]
);

has 'tabletype' => (
    is => 'ro',
    isa => 'Str',
    default => 'table',
    documentation => q[Table type according to DBI->table_info]
);

has 'sqlsnippetdir' => (
    isa => 'Str',
    is => 'ro',
    documentation => q[Directory containing sql update files],
);

has '_schemadump' => (
    isa=>'Str',
    is=>'rw',
    lazy_build=>1,
    clearer=>'reset_checksum',
);

# mainly needed for scripts
has 'verbose'      => ( is => 'rw', isa => 'Bool', default => 0 );
has 'dump_checksums' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'dry_run'      => ( is => 'rw', isa => 'Bool', default => 0 );

# internal

has '_update_path' => ( is => 'rw', isa => 'HashRef', lazy_build=>1 );

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

=head3 schema_update.pl

Updates a schema based on the current checksum and SQL snippet files 

=head1 METHODS 

=head2 Public Methods

=cut

sub checksum {
    my $self = shift;
    return Digest::SHA1::sha1_hex($self->_schemadump);
}

=head3 schemadump

    my $schemadump = $self->schemadump;

Returns a string representation of the whole schema (as a Data::Dumper 
Dump).

=cut

sub _build__schemadump {
    my $self = shift;

    my $tabletype = $self->tabletype;
    my $catalog   = $self->catalog;

    my $dbh = $self->dbh;

    my @metadata = qw(COLUMN_NAME COLUMN_SIZE NULLABLE TYPE_NAME COLUMN_DEF);

    my %relevants = ();
    foreach my $schema ( @{ $self->schemata } ) {
        foreach
            my $table ( $dbh->tables( $catalog, $schema, '%', $tabletype ) )
        {
            $table=~s/"//g;
            my %data;

            # remove schema name from table
            my $t = $table;
            $t =~ s/^.*?\.//;

            my @pks = $dbh->primary_key( $catalog, $schema, $t );
            $data{primary_keys} = \@pks if @pks;

            # columns
            my $sth_col = $dbh->column_info( $catalog, $schema, $t, '%' );

            my $column_info = $sth_col->fetchall_hashref('COLUMN_NAME');

            while ( my ( $column, $data ) = each %$column_info ) {
                my $info = { map { $_ => $data->{$_} } @metadata };

                # add postgres enums
                if ( $data->{pg_enum_values} ) {
                    $info->{pg_enum_values} = $data->{pg_enum_values};
                }

                # some cleanup
                if (my $default = $info->{COLUMN_DEF}) {
                    if ( $default =~ /nextval/ ) {
                        $default =~ m{'([\w\.\-_]+)'};
                        if ($1) {
                            my $new = $1;
                            $new =~ s/^\w+\.//;
                            $default = 'nextval:' . $new;
                        }
                    }
                    $default=~s/["'\(\)\[\]\{\}]//g;
                    $info->{COLUMN_DEF}=$default;
                }

                $info->{TYPE_NAME} =~ s/^(?:.+\.)?(.+)$/$1/g;

                $data{columns}{$column} = $info;
            }

            # foreign keys
            my $sth_fk
                = $dbh->foreign_key_info( '', '', '', $catalog, $schema, $t );
            if ($sth_fk) {
                $data{foreign_keys} = $sth_fk->fetchall_arrayref( {
                        map { $_ => 1 }
                            qw(FK_NAME UK_NAME UK_COLUMN_NAME FK_TABLE_NAME FK_COLUMN_NAME UPDATE_RULE DELETE_RULE)
                    }
                );
                # Nasty workaround
                foreach my $row (@{$data{foreign_keys}}) {
                    $row->{DEFERRABILITY} = undef;
                }
            }

            # postgres unique constraints
            # very crude hack to see if we're running postgres
            if ( $INC{'DBD/Pg.pm'} ) {
                my @unique;
                my $sth=$dbh->prepare( "select indexdef from pg_indexes where schemaname=? and tablename=?");
                $sth->execute($schema, $t);
                while (my ($index) =$sth->fetchrow_array) {
                    $index=~s/$schema\.//g;
                    push(@unique,$index);
                }
                @unique = sort (@unique);
                $data{unique_keys} = \@unique if @unique;
            }

            $relevants{$table} = \%data;
        }

    }
    my $dumper = Data::Dumper->new( [ \%relevants ] );
    $dumper->Sortkeys(1);
    $dumper->Indent(1);
    my $dump = $dumper->Dump;
    return $dump;
}

=head3 build_update_path

    my $update_info = $self->build_update_path( '/path/to/sql/snippets' )

Builds the datastructure needed by L<apply_sql_update>.
C<build_update_path> reads in all files ending in ".sql" in the
directory passed in (or defaulting to C<< $self->sqlsnippetdir >>). It 
builds something like a linked list of files, which are chained by 
their C<preSHA1sum> and C<postSHA1sum>.

=cut

sub _build__update_path {
    my $self = shift;
    my $dir = $self->sqlsnippetdir;
    croak("Please specify sqlsnippetdir") unless $dir;
    croak("Cannot find sqlsnippetdir: $dir") unless -d $dir;

    say "Checking directory $dir for checksum_files" if $self->verbose;

    my %update_info;
    my @files = File::Find::Rule->file->name('*.sql')->in($dir);

    foreach my $file ( sort @files ) {
        my ( $pre, $post ) = $self->get_checksums_from_snippet($file);

        if ( !$pre && !$post ) {
            say "skipping $file (has no checksums)" if $self->verbose;
            next;
        }

        if ( $pre eq $post ) {
            if ( $update_info{$pre} ) {
                my @new = ('SAME_CHECKSUM');
                foreach my $item ( @{ $update_info{$pre} } ) {
                    push( @new, $item ) unless $item eq 'SAME_CHECKSUM';
                }
                $update_info{$pre} = \@new;
            }
            else {
                $update_info{$pre} = ['SAME_CHECKSUM'];
            }
        }

        if (   $update_info{$pre}
            && $update_info{$pre}->[0] eq 'SAME_CHECKSUM' )
        {
            if ( $post eq $pre ) {
                splice( @{ $update_info{$pre} },
                    1, 0, Path::Class::File->new($file), $post );
            }
            else {
                push( @{ $update_info{$pre} },
                    Path::Class::File->new($file), $post );
            }
        }
        else {
            $update_info{$pre} = [ Path::Class::File->new($file), $post ];
        }
    }

    return $self->_update_path( \%update_info ) if %update_info;
    return;
}

=head3 get_checksums_from_snippet

    my ($pre, $post) = $self->get_checksums_from_snippet( $file );

Returns a list of the preSHA1sum and postSHA1sum for the given file.

The file has to contain this info in SQL comments, eg:

  -- preSHA1sum: 89049e457886a86886a4fdf1f905b69250a8236c
  -- postSHA1sum: d9a02517255045167053ea92dace728e1389f8ca

  alter table foo add column bar;

=cut

sub get_checksums_from_snippet {
    my ($self, $filename) = @_;
    die "need a filename" unless $filename;

    my %checksums;

    open( my $fh, "<", $filename ) || croak "Cannot read $filename: $!";
    while (<$fh>) {
        if (m/^--\s+(pre|post)SHA1sum:?\s+([0-9A-Fa-f]{40,})\s+$/) {
            $checksums{$1} = $2;
        }
    }
    close $fh;
    return map { $checksums{$_} || '' } qw(pre post);
}

=head2 Attributes generated by Moose

All of this methods can also be set from the commandline. See 
MooseX::Getopts.

=head3 dbh

The database handle (DBH::db). 

=head3 dsn

The dsn.

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

This module was written for revdev L<http://www.revdev.at>, a nice 
litte software company run by Koki, Domm 
(L<http://search.cpan.org/~domm/>) and Maros 
(L<http://search.cpan.org/~maros/>).

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, revdev.at, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included 
with this module.

=cut
