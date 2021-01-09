package DBIx::SchemaChecksum::App;

# ABSTRACT: Manage your datebase schema via checksums
# VERSION

use 5.010;
use MooseX::App 1.21 qw(Config ConfigHome);
extends qw(DBIx::SchemaChecksum);

use DBI;

option 'dsn' => (
    isa           => 'Str',
    is            => 'ro',
    required      => 1,
    documentation => q[DBI Data Source Name]
);
option 'user' => (
    isa           => 'Str',
    is            => 'ro',
    documentation => q[username to connect to database]
);
option 'password' => (
    isa           => 'Str',
    is            => 'ro',
    documentation => q[password to connect to database]
);
option [qw(+catalog +schemata +driveropts)] => ();

has '+dbh' => ( lazy_build => 1 );

sub _build_dbh {
    my $self = shift;
    return DBI->connect(
        $self->dsn, $self->user, $self->password,
        { RaiseError => 1 }    # TODO: set dbi->connect opts via App
    );
}

__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 DESCRIPTION

Manage your datebase schema via checksums

=over

=item * Use C<checksum> to calculate the current checksum of your database.

=item * Use C<new_changes_file> to generate a new db update script based on the current checksum.

=item * Use C<apply_changes> to apply all update scripts starting from the current checksum.

=back

For more background information, check out the man-page via C<perldoc DBIx::SchemaChecksum> or on L<https://metacpan.org/pod/DBIx::SchemaChecksum>

=cut

