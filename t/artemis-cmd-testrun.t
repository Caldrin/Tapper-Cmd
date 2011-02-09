#!perl

use Artemis::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use 5.010;

use warnings;
use strict;

use Test::More;
use YAML::Syck;

use Artemis::Cmd::Testrun;
use Artemis::Model 'model';


# -----------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------

my $cmd = Artemis::Cmd::Testrun->new();
isa_ok($cmd, 'Artemis::Cmd::Testrun', '$testrun');

#######################################################
#
#   check support methods
#
#######################################################

my $user_id = Artemis::Model::get_or_create_user('sschwigo');
is($user_id, 12, 'get user id for login');


#######################################################
#
#   check add method
#
#######################################################

my $testrun_args = {notes     => 'foo',
                    shortname => 'foo',
                    topic     => 'foo',
                    earliest  => DateTime->new( year   => 1964,
                                                month  => 10,
                                                day    => 16,
                                                hour   => 16,
                                                minute => 12,
                                                second => 47),
                    requested_hosts => ['iring','bullock'],
                    owner           => 'sschwigo'};

my $testrun_id = $cmd->add($testrun_args);
ok(defined($testrun_id), 'Adding testrun');
my $testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id})->first;
my $retval = {owner       => $testrun->owner_user_id,
              notes       => $testrun->notes,
              shortname   => $testrun->shortname,
              topic       => $testrun->topic_name,
              earliest    => $testrun->starttime_earliest,
              requested_hosts => [ map {$_->host->name} $testrun->testrun_scheduling->requested_hosts->all ],
             };
$testrun_args->{owner}    =  12;
is_deeply($retval, $testrun_args, 'Values of added test run');


#######################################################
#
#   check update method
#
#######################################################

my $testrun_id_new = $cmd->update($testrun_id, {hostname => 'iring'});
is($testrun_id_new, $testrun_id, 'Updated testrun without creating a new one');

$testrun = model('TestrunDB')->resultset('Testrun')->search({id => $testrun_id})->first;
$retval = {
           owner       => $testrun->owner_user_id,
           notes       => $testrun->notes,
           shortname   => $testrun->shortname,
           topic       => $testrun->topic_name,
           earliest    => $testrun->starttime_earliest,
           requested_hosts => [ map {$_->host->name} $testrun->testrun_scheduling->requested_hosts->all ],
          };
is_deeply($retval, $testrun_args, 'Values of updated test run');

#######################################################
#
#   check rerun method
#
#######################################################

$testrun_id_new = $cmd->rerun($testrun_id);
isnt($testrun_id_new, $testrun_id, 'Rerun testrun with new id');

$testrun        = model('TestrunDB')->resultset('Testrun')->find($testrun_id);
my $testrun_new = model('TestrunDB')->resultset('Testrun')->find($testrun_id_new);

$retval = { owner       => $testrun->owner_user_id,
            notes       => $testrun->notes,
            shortname   => $testrun->shortname,
            topic       => $testrun->topic_name,
          };
$testrun_args = {owner       => $testrun_new->owner_user_id,
                 notes       => $testrun_new->notes,
                 shortname   => $testrun_new->shortname,
                 topic       => $testrun_new->topic_name,
          };
is_deeply($retval, $testrun_args, 'Values of rerun test run');

my @precond_array     = $testrun_new->ordered_preconditions;
my @precond_array_old = $testrun->ordered_preconditions;
is_deeply(\@precond_array, \@precond_array_old, 'Rerun testrun with same preconditions');



#######################################################
#
#   check del method
#
#######################################################

$retval = $cmd->del(101);
is($retval, 0, 'Delete testrun');
$testrun = model('TestrunDB')->resultset('Testrun')->find(101);
is($testrun, undef, 'Delete correct testrun');

my $tr_spec = YAML::Syck::LoadFile('t/misc_files/testrun.mpc');
my @testruns = $cmd->create($tr_spec->{description});
is(int @testruns, 4, 'Testruns created from requested_hosts_all, requested_hosts_any, requested_hosts_any');

TODO: {
        local $TODO = 'searching all hosts with a given feature set is not yet implemented';
        is(int @testruns, 6, 'Testruns created from all requests');
}

for (my $i=1; $i<=2; $i++) {
        $testrun = model('TestrunDB')->resultset('Testrun')->find(shift @testruns);
        is($testrun->testrun_scheduling->requested_hosts->count, 1, "$i. requested_host_all testrun with one requested host");
}

$testrun = model('TestrunDB')->resultset('Testrun')->find(shift @testruns);
is($testrun->testrun_scheduling->requested_hosts->count, 2, "requested_host_any testrun with two requested hosts");

$testrun = model('TestrunDB')->resultset('Testrun')->find(shift @testruns);
is($testrun->testrun_scheduling->requested_features->count, 2, "requested_features_any testrun with two requested features");


done_testing;
