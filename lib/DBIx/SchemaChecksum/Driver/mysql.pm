package DBIx::SchemaChecksum::Driver::mysql;
use utf8;

use namespace::autoclean;
use Moose::Role;

around '_build_schemadump_table' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;
    return if $schema =~ /information_schema/;

    die "Sorry, but mysql isn't supported at the moment, because it's introspection seems to be broken.\n";

    return $self->$orig($schema,$table);
};

1;
