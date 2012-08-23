package DBIx::SchemaChecksum::App::ApplyChanges;
use 5.010;
use MooseX::App qw(Config);
extends qw(DBIx::SchemaChecksum::App);
use Carp qw(croak);

option '+sqlsnippetdir' => ( required => 1);

sub run {
    my $self = shift;

    my $pre_checksum = $self->checksum;
#    say "Base checksum: $pre_checksum" if $self->verbose;

    $self->build_update_path( );
    $self->apply_sql_snippets($pre_checksum);
}

=head3 apply_sql_snippets

    $self->apply_sql_snippets( $starting_checksum );

Applies SQL snippets in the correct order to the DB. Checks if the
checksum after applying the snippets is correct. If it isn't correct
rolls back the last change (if your DB supports transactions...)

=cut

sub apply_sql_snippets {
    my $self          = shift;
    my $this_checksum = shift;
    croak "No current checksum" unless $this_checksum;
    my $update_path = $self->_update_path;

    my $update = $update_path->{$this_checksum}
        if ( exists $update_path->{$this_checksum} );

    unless ($update) {
        my $this_checksum = $self->checksum;
        $self->dump_checksum($this_checksum) if $self->dump_checksums;
        die "No update found that's based on $this_checksum.";
    }

    if ( $update->[0] eq 'SAME_CHECKSUM' ) {
        return unless $update->[1];
        my ( $file, $expected_post_checksum ) = splice( @$update, 1, 2 );

        $self->apply_file( $file, $expected_post_checksum );
    }
    else {
        $self->apply_file(@$update);
    }
}

sub apply_file {
    my ( $self, $file, $expected_post_checksum ) = @_;

    if ($self->show_update_path) {
        print $file->basename." (".$expected_post_checksum.")\n";
        return $self->apply_sql_snippets($expected_post_checksum);
    }

    my $no_checksum_change;
    $no_checksum_change=1 if $self->checksum eq $expected_post_checksum;

    my $yes = 0;
    if ( $self->no_prompt ) {
        $yes = 1;
        print "Applying " .$file->basename. "\n";
    }
    else {
        my $ask_user = 1;
        while ($ask_user) {
            print "Do you want me to apply <" . $file->basename . ">".($no_checksum_change ?" (won't change the checksum)" : '')."? [y/n".( $no_checksum_change ?'/s' : '')."] ";
            my $in = <STDIN>;
            chomp($in);
            if ( $in =~ /^y/i ) {
                $yes      = 1;
                $ask_user = 0;
            }
            elsif ( $in =~ /^n/i ) {
                $yes      = 0;
                $ask_user = 0;
            }
            elsif ( $no_checksum_change &&  $in =~ /^s/i) {
                return $self->apply_sql_snippets($expected_post_checksum);
            }
        }
    }

    if ($yes) {
        say("Applying the patch") if $self->verbose;
        my $content = $file->slurp;

        my $dbh = $self->dbh;
        $dbh->begin_work;

		my $split_regex = qr/(?!:[\\]);/;

		if ($content =~ m/--\s*split-at:\s*(\S+)\n/s) {
			warn "Splitting $file commands at >$1<";
			$split_regex = qr/$1/;
		}

        $content =~ s/^\s*--.+$//gm;
        foreach my $command ( split( $split_regex , $content ) ) {
            $command =~ s/\A\s+//;
            $command =~ s/\s+\Z//;

            next unless $command;
            if ( $self->dry_run ) {
                say "dry run!" if $self->verbose;
            }
            else {
                say "Executing: $command" if $self->verbose;
                eval { $dbh->do($command) };
                if ($@) {
                    $dbh->rollback;
                    say "SQL error: $@";
                    say "ABORTING!";
                    exit;
                }
            }
        }

        if ( $self->dry_run ) {
            $dbh->rollback;
            say "dry run, so checksums cannot match. We proceed anyway...";
            return $self->apply_sql_snippets($expected_post_checksum);
        }

        # new checksum
        $self->_schemadump('');
        my $post_checksum = $self->checksum;
        $self->dump_checksum($post_checksum) if $self->dump_checksums;

        if ( $post_checksum eq $expected_post_checksum ) {
            say "post checksum OK";
            $dbh->commit;
            return $self->apply_sql_snippets($post_checksum);
        }
        else {
            say "post checksum mismatch!";
            say "  expected $expected_post_checksum";
            say "  got      $post_checksum";
            $dbh->rollback;
            say "ABORTING!";
            exit;
        }
    }
    else {
        say "I am not applying this file. So I stop.";
        exit;
    }
}

1;
