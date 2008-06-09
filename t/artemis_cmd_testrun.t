#! /usr/bin/env perl

use strict;
use warnings;

use t::Tools;
use Test::Fixture::DBIC::Schema;
use Artemis::Cmd::Testrun;
use Artemis::Cmd::Testrun::Command::list;
use Artemis::Cmd::Testrun::Command::new;
use Test::More tests => 9;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $testrun = Artemis::Cmd::Testrun::Command::list::_get_testrun_by_id (23); # perfmon

is($testrun->id, 23, "testrun id");
is($testrun->notes, 'perfmon', "testrun notes");
is($testrun->shortname, 'perfmon', "testrun shortname");
is($testrun->topic_name, 'Software', "testrun topic_name");
is($testrun->topic->name, 'Software', "testrun topic->name");
is($testrun->topic->description, 'any non-kernel software, e.g., libraries, programs', "testrun topic->description");
is($testrun->test_program, '/usr/local/share/artemis/testsuites/perfmon/t/do_test.sh', "testrun test_program");

is(Artemis::Cmd::Testrun::_get_user_for_login('sschwigo')->id, 12, "_get_systems_id_for_hostname");

TODO: {
        local $TODO = 'do not forget to implement some subs';

        isnt(Artemis::Cmd::Testrun::_get_systems_id_for_hostname(), 42, "implemented _get_systems_id_for_hostname");
}
