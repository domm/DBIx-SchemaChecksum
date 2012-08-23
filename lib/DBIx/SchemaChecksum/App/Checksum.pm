package DBIx::SchemaChecksum::App::Checksum;
use 5.010;
use MooseX::App qw(Config);
extends qw(DBIx::SchemaChecksum::App);

sub run {
    my $self = shift;
    say $self->scs->checksum;
}
1;
