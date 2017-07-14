package DBIx::SchemaChecksum::Driver::mysql;
use utf8;

# ABSTRACT: MySQL driver for DBIx::SchemaChecksum

use namespace::autoclean;
use Moose::Role;

around '_build_schemadump_table' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;

    die "Sorry, but mysql isn't supported at the moment, because it's introspection seems to be broken.\n";
};

1;

=pod

=head1 DESCRIPTION

MySQL is B<not> supported!

