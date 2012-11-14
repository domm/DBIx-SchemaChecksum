# ============================================================================
package DBIx::SchemaChecksum::Driver::Pg;
# ============================================================================
use utf8;

use namespace::autoclean;
use Moose::Role;

around '_build_schemadump_column' => sub {
    my $orig = shift;
    my ($self,$schema,$table,$column,$data) = @_;

    my $relevants = $self->$orig($schema,$table,$column,$data);

    # add postgres enums
    if ( $data->{pg_enum_values} ) {
        $relevants->{pg_enum_values} = $data->{pg_enum_values};
    }

    return $relevants;
};

around '_build_schemadump_table' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;

    my $dbh = $self->dbh;

    my $relevants = $self->$orig($schema,$table);

    # Indexes
    {
        my $sth_indexes = $dbh->prepare(q[SELECT indexdef
            FROM pg_catalog.pg_indexes
            WHERE schemaname=?
            AND tablename=?]);

        $sth_indexes->execute($schema, $table);

        my @indexes;
        while (my ($index) = $sth_indexes->fetchrow_array) {
            $index=~s/$schema\.//g;
            push(@indexes,$index);
        }

        @indexes = sort (@indexes);
        $relevants->{indexes} = \@indexes
            if @indexes;
    }

    # Triggers
    if ($self->driveropts->{triggers}) {
        my $sth_triggers = $dbh->prepare(q[SELECT pg_get_triggerdef(x.oid)
            FROM pg_catalog.pg_trigger x
            JOIN pg_catalog.pg_class c ON c.oid = x.tgrelid
            LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'r'::"char"
            AND x.tgisinternal = FALSE
            AND n.nspname = ?
            AND c.relname = ?]);

        $sth_triggers->execute($schema, $table);

        my @triggers;
        while (my ($index) = $sth_triggers->fetchrow_array) {
            $index=~s/$schema\.//g;
            push(@triggers,$index);
        }

        @triggers = sort (@triggers);
        $relevants->{triggers} = \@triggers
            if @triggers;
    }

    return $relevants;
};

around '_build_schemadump_schema' => sub {
    my $orig = shift;
    my ($self,$schema) = @_;

    my $relevants = $self->$orig($schema);
    $relevants->{sequences} = $self->_build_schemadump_sequences($schema) if $self->driveropts->{sequences};
    $relevants->{functions} = $self->_build_schemadump_functions($schema) if $self->driveropts->{functions};

    return $relevants;
};

sub _build_schemadump_sequences {
    my ($self,$schema) = @_;

    my $dbh = $self->dbh;
    # TODO introspect increment, min, max, cache and cycle
    my $sth_sequences = $dbh->prepare(q[SELECT c.relname
        FROM pg_catalog.pg_class c
        LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'S'::"char"
        AND n.nspname LIKE ?
        AND n.nspname <> 'pg_catalog'
        ORDER BY 1]);

    $sth_sequences->execute($schema);

    my @sequences;
    while (my ($index) = $sth_sequences->fetchrow_array) {
        push(@sequences,$index);
    }

    return \@sequences;
};

sub _build_schemadump_functions {
    my ($self,$schema) = @_;

    my $dbh = $self->dbh;

    # TODO handle aggregate and windowing functions
    my $sth_functions = $dbh->prepare(q[SELECT pg_get_functiondef(x.oid)
        FROM pg_catalog.pg_proc x
        LEFT JOIN pg_namespace n ON n.oid = x.pronamespace
        WHERE proisagg = FALSE
        AND proiswindow = FALSE
        AND n.nspname LIKE ?
        AND n.nspname <> 'pg_catalog'
        ORDER BY 1]);

    $sth_functions->execute($schema);

    my @functions;
    while (my ($index) = $sth_functions->fetchrow_array) {
        push(@functions,$index);
    }

    return \@functions
};

1;
