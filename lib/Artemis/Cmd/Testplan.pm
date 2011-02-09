package Artemis::Cmd::Testplan;

use Moose;
use Artemis::Model 'model';
use YAML::Syck;

use parent 'Artemis::Cmd';

=head1 NAME

Artemis::Cmd::Testplan - Backend functions for manipluation of testplan instances in the database

=head1 SYNOPSIS

This project offers functions to add, delete or update testplan
instances in the database.

    use Artemis::Cmd::Testplan;

    my $cmd = Artemis::Cmd::Testplan->new();
    my $plan_id = $cmd->add($plan);
    $cmd->update($plan_id, $new_plan);
    $cmd->del($plan_id);

    ...

=head1 FUNCTIONS

=cut

=head2 add

Add a new testplan instance to database and create the associated
testruns. The function expects a string containing the evaluated test
plan content and a path.

@param string - plan content
@param string - path

@return int - testplan instance id

=cut

sub add {
        my ($self, $plan_content, $path) = @_;

        my $instance = model('TestrunDB')->resultset('TestplanInstance')->new({evaluated_testplan => $plan_content, path => $path});
        $instance->insert;

        my @testrun_ids;

        my @plans = YAML::Syck::Load($plan_content);
        foreach my $plan (@plans) {
                my $type = $plan->{type};
                $type = ucfirst($type);
                eval "use Artemis::Cmd::$type";
                my $handler = "Artemis::Cmd::$type"->new();
                my @new_ids = $handler->create($plan->{description}, $instance->id);
                push @testrun_ids, @new_ids;
        }
        return $instance->id;
}


=head2 update


=cut

sub update {
        my ($self, $id, $args) = @_;
}

=head2 del


=cut

sub del {
        my ($self, $id) = @_;
        my $testplan = model('TestrunDB')->resultset('TestplanInstance')->find($id);
        $testplan->delete();
        return 0;
}


=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<osrc-sysin at elbe.amd.com>, or through
the web interface at L<https://osrc/bugs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2011 OSRC SysInt Team, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Artemis::Cmd::Testplan
