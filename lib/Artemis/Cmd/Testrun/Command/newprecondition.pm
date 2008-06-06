package Artemis::Cmd::Testrun::Command::newprecondition;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use File::Slurp;

use Artemis::Cmd::Testrun;
use Data::Dumper;

sub opt_spec {
        return (
                [ "verbose",                           "some more informational output"                                                                                        ],
                [ "shortname=s",                       "TEXT; shortname", { required => 1 }                                                                                    ],
                [ "condition=s",                       "TEXT; condition description in YAML format (see Spec)"                                                                 ],
                [ "condition_file=s",                  "STRING; filename that contains the condition (alternative to --condition)"                                             ],
                [ "precondition=s@",                   "INT; assigned pre-precondition ids"                                                                                    ],
               );
}

sub usage_desc
{
        "artemis-testrun newprecondition --shortname=s  ( --condition=s | --condition_file=s ) ";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

#         print "opt  = ", Dumper($opt);
#         print "args = ", Dumper($args);

        print "Missing argument --shortname\n"            unless $opt->{shortname};

        print "Only one of --condition or --condition_file allowed.\n" if $opt->{condition} && $opt->{condition_file};

        return 1 if $opt->{shortname};
        die $self->usage->text;
}

sub run {
        my ($self, $opt, $args) = @_;

        require Artemis;

        $self->new_precondition ($opt, $args);
}

sub read_condition_file
{
        my ($condition_file) = @_;

        my $condition;

        # read from file or STDIN if filename == '-'
        if ($condition_file) {
                if ($condition_file eq '-') {
                        $condition = read_file (\*STDIN);
                } else {
                        $condition = read_file ($condition_file);
                }
        }
        return $condition;
}

sub new_precondition
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $shortname                       = $opt->{shortname}    || '';
        my $repository_full_name            = $opt->{repository_full_name};
        my $type                            = $opt->{type};
        my $condition                       = $opt->{condition};
        my $condition_file                  = $opt->{condition_file};
        my $reboot_needed_after_preparation = $opt->{reboot_needed_after_preparation};
        my $timeout                         = $opt->{timeout};

        $condition = read_condition_file($condition_file);

        my $precondition = Artemis->model('TestrunDB')->resultset('Precondition')->new
            ({
              shortname                       => $shortname,
              repository_full_name            => $repository_full_name,
              type                            => $type,
              condition                       => $condition,
              reboot_needed_after_preparation => $reboot_needed_after_preparation,
              timeout                         => $timeout,
             });
        $precondition->insert;
        $self->assign_preconditions($opt, $args, $precondition);
        print $opt->{verbose} ? $precondition->to_string : $precondition->id, "\n";
}

sub assign_preconditions {
        my ($self, $opt, $args, $precondition) = @_;

        my @ids = @{ $opt->{precondition} || [] };

        my $succession = 1;
        foreach (@ids) {
                my $pre_precondition = Artemis->model('TestrunDB')->resultset('PrePrecondition')->new
                    ({
                      parent_precondition_id => $precondition->id,
                      child_precondition_id  => $_,
                      succession             => $succession,
                     });
                $pre_precondition->insert;
                $succession++
        }
}


# perl -Ilib bin/artemis-testrun newprecondition --shortname=perl-5.10 --repository_full_name=/package/redhat/5.2/64bit/perl-5.10 --type=foo

1;
