package DBIx::SchemaChecksum::Driver::SQLite;

# ABSTRACT: SQLite driver for DBIx::SchemaChecksum
# VERSION

use utf8;
use namespace::autoclean;
use Moose::Role;

around '_build_schemadump_table' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;

    return
        if ($table eq 'sqlite_temp_master' && $schema eq 'temp')
        || ($table eq 'sqlite_sequence' && $schema eq 'main')
        || ($table eq 'sqlite_master' && $schema eq 'main');

    return $self->$orig($schema,$table);
};

1;

__END__

=pod

=head1 DESCRIPTION

Ignore some internal sqlite tables


