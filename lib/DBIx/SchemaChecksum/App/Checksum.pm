package DBIx::SchemaChecksum::App::Checksum;
use 5.010;
use MooseX::App qw(Config);
extends qw(DBIx::SchemaChecksum::App);

option 'show_dump' => (
    is            => 'ro',
    isa           => 'Bool',
    documentation => q[Show the raw database dump structure],
    default       => 0,
);

sub run {
    my $self = shift;

    say $self->scs->schemadump if $self->show_dump;
    say $self->scs->checksum;
}
1;
