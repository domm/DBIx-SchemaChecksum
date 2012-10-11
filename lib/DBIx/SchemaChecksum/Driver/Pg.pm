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

around '_build_schemadump_taböe' => sub {
    my $orig = shift;
    my ($self,$schema,$table) = @_;
    
    my $dbh = $self->dbh;
    
    my $relevants = $self->$orig($schema,$table);
    
    my @unique;
    my $sth=$dbh->prepare( "SELECT indexdef 
        FROM pg_indexes 
        WHERE schemaname=? AND tablename=?");
    $sth->execute($schema, $table);
    
    while (my ($index) = $sth->fetchrow_array) {
        $index=~s/$schema\.//g;
        push(@unique,$index);
    }
    
    @unique = sort (@unique);
    $relevants->{unique_keys} = \@unique
        if @unique;
    
    return $relevants;
};


1;