package DBIx::SchemaChecksum::App::NewChangesFile;
use 5.010;
use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);

sub run {}

__PACKAGE__->meta->make_immutable();
1;
