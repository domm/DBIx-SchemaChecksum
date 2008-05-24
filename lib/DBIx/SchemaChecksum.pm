package DBIx::SchemaChecksum;

use 5.010;
use Moose;
use version; our $VERSION = version->new('0.06');

use DBI;
use Digest::SHA1;
use Data::Dumper;
use Path::Class;
use Carp;
use IO::Prompt;

with 'MooseX::Getopt';

has 'dsn' => ( isa => 'Str', is => 'ro', required => 1 );
has 'user'     => ( isa => 'Str', is => 'ro' );
has 'password' => ( isa => 'Str', is => 'ro' );

has 'catalog' => ( is => 'ro', isa => 'Str', default => '%' );
has 'schemata' =>
  ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { ['%'] } );
has 'tabletype' => ( is => 'ro', isa => 'Str', default => 'table' );

has 'sqlsnippetdir' => ( isa => 'Str', is => 'ro' );

# mainly needed for scripts
has 'verbose'   => ( is => 'ro', isa => 'Bool', default => 0 );
has 'no_prompt' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'dry_run'   => ( is => 'ro', isa => 'Bool', default => 0 );

# internal
has '_dbh'         => ( isa => 'DBI::db', is  => 'rw' );
has '_schemadump'  => ( is  => 'rw',      isa => 'Str' );
has '_update_path' => ( is  => 'rw',      isa => 'HashRef' );

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

=head3 BUILD

Moose Object Builder which sets up the DB connection.

=cut

sub BUILD {
    my $self = shift;
    my $dbh =
      DBI->connect( $self->dsn, $self->user, $self->password,
        { RaiseError => 1 } );
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

=head3 apply_sql_snippets

    $self->apply_sql_snippets( $starting_checksum );

Applies SQL snippets in the correct order to the DB. Checks if the 
checksum after applying the snippets is correct. If it isn't correct 
rolls back the last change (if your DB supports transactions...)

=cut

sub apply_sql_snippets {
    my $self          = shift;
    my $this_checksum = shift;
    croak "No current checksum" unless $this_checksum;

    my $update_path = $self->_update_path;

    my $update = $update_path->{$this_checksum}
      if ( exists $update_path->{$this_checksum} );

    unless ($update) {
        croak "No update found that's based on $this_checksum.\n";
    }

    my ( $file, $expected_post_checksum ) = @$update;

    my $yes = 0;
    if ( $self->no_prompt ) {
        $yes = 1;
    }
    elsif (
        prompt(
            "Do you want me to apply <" . $file->basename . ">? [y/n] ", '-yn1'
        )
      )
    {
        $yes = 1;
    }

    if ($yes) {
        say("Applying the patch") if $self->verbose;
        my $content = $file->slurp;

        my $dbh = $self->_dbh;
        $dbh->begin_work;

        $content =~ s/^\s*--.+$//gm;
        foreach my $command ( split( /(?!:[\\]);/, $content ) ) {
            $command =~ s/\A\s+//;
            $command =~ s/\s+\Z//;

            next unless $command;
            if ( $self->dry_run ) {
                say "dry run!" if $self->verbose;
            }
            else {
                say "Executing: $command" if $self->verbose;
                eval { $dbh->do($command) };
                if ($@) {
                    $dbh->rollback;
                    say "SQL error: $@";
                    croak "ABORTING!\n";
                }
            }
        }

        if ( $self->dry_run ) {
            $dbh->rollback;
            say "dry run, so checksums cannot match. We proceed anyway...";
            return $self->apply_sql_snippets($expected_post_checksum);
        }

        # new checksum
        $self->_schemadump('');
        my $post_checksum = $self->checksum;
        if ( $post_checksum eq $expected_post_checksum ) {
            say "post checksum OK";
            $dbh->commit;
            return $self->apply_sql_snippets($post_checksum);
        }
        else {
            say "post checksum mismatch!";
            say "  expected $expected_post_checksum";
            say "  got      $post_checksum";
            $dbh->rollback;
            croak "ABORTING!\n";
        }
    }
    else {
        croak "I am not applying this file. So I stop.\n";
    }
}

=head3 build_update_path

    my $update_info = $self->build_update_path( '/path/to/sql/snippets' )

Builds the datastructure needed by L<apply_sql_update>.
C<build_update_path> reads in all files ending in ".sql" in the
directory passed in (or defaulting to C<< $self->sqlsnippetdir >>). It 
builds something like a linked list of files, which are chained by 
their C<preSHA1sum> and C<postSHA1sum>.

=cut

sub build_update_path {
    my $self = shift;
    my $dir  = shift || $self->sqlsnippetdir;
    croak("Please specify sqlsnippetdir") unless $dir;
    croak("Cannot find sqlsnippetdir: $dir") unless -d $dir;

    say "Checking directory $dir for checksum_files" if $self->verbose;

    my %update_info;
    my @files = glob( $dir . "/*.sql" );

    foreach my $file (@files) {
        my ( $pre, $post ) = $self->get_checksums_from_snippet($file);
        $update_info{$pre} = [ Path::Class::File->new($file), $post ];
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
    my $self     = shift;
    my $filename = shift;
    croak "Need a filename" unless $filename;

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
