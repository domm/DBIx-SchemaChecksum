package DBIx::SchemaChecksum::App::NewChangesFile;
use 5.010;

# ABSTRACT: DBIx::SchemaChecksum command new_changes_file

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);

sub run {}

__PACKAGE__->meta->make_immutable();
1;
