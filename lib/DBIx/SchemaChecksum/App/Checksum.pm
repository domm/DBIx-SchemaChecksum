package DBIx::SchemaChecksum::App::Checksum;

# ABSTRACT: get the current DB checksum
# VERSION

use 5.010;

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);

option 'show_dump' => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => q[Show the raw database dump structure],
    default       => 0,
);

sub run {
    my $self = shift;

    say $self->checksum;
    say $self->_schemadump if $self->show_dump;
}

__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 DESCRIPTION

Calculate the current checksum and report it. Use C<--show_dump> to
show the string dump on which the checksum is based.

=cut

