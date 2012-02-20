# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is the Inline Editor Bugzilla Extension.
#
# The Initial Developer of the Original Code is "Nokia Corporation"
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Visa Korhonen <visa.korhonen@symbio.com>

package Bugzilla::Extension::EnhancedTreeView::BugRPCLib;

#use lib qw(./extensions/EnhancedTreeView/lib);

use Bugzilla::Error;
use Bugzilla::Util qw(trick_taint);

use JSON::XS;

use strict;
use base qw(Exporter);

our @EXPORT = qw(
  update_bug_fields_from_json
  check_bug_status
  );
#
# Important!
# Data needs to be in exact format:
#
#
#  { "method": "Bug.update", "params": {"ids" : [ { 216089 : { "estimated_time" : 0.8 } } ] }, "id" : 0 }
#  { "method": "Bug.update", "params": {"ids" : [ { 216089 : { "bug_status" : "ASSIGNED", "comment" : "Test comment" } } ] }, "id" : 0 }
#

sub update_bug_fields_from_json {
    my ($vars) = @_;

    my $cgi    = Bugzilla->cgi;
    my $action = $cgi->param('action');    # Future use
    my $data   = $cgi->param('data');

    my $json = new JSON::XS;
    if ($data =~ /(.*)/) {
        $data = $1;                        # $data now untainted
    }
    my $content = $json->allow_nonref->utf8->relaxed->decode($data);

    my ($params, $bug_obj_array_ref, $field_value);
    $params = $content->{params};

    $bug_obj_array_ref = $params->{ids};
    my @bug_obj_array = @{$bug_obj_array_ref};
    for my $bug_obj (@bug_obj_array) {
        my @this_bug_id     = keys %{$bug_obj};
        my $bug_id          = $this_bug_id[0];
        my $bug_fields      = $bug_obj->{$bug_id};
        my @bug_field_names = keys %{$bug_fields};

        my $comment_value = undef;
        if (grep { $_ eq "comment" } @bug_field_names) {
            $comment_value = $bug_fields->{"comment"};
        }
        @bug_field_names = grep { $_ ne "comment" } @bug_field_names;

        my $field_name = $bug_field_names[0];
        $field_value = $bug_fields->{$field_name};
        update_bug_field($vars, $bug_id, $field_name, $field_value, $comment_value);
    }
}

sub update_bug_field {
    my ($vars, $bug_id, $field_name, $field_value, $comment_value) = @_;

    my $bug = Bugzilla::Bug->new($bug_id);
    my $old_value;
    if ($field_name eq 'estimated_time') {
        $bug->set_estimated_time($field_value);
        $bug->update();
    }
    elsif ($field_name eq 'remaining_time') {
        $bug->set_remaining_time($field_value);
        $bug->update();
    }
    elsif ($field_name eq 'assigned_to') {
        if (Bugzilla::User::login_to_id($field_value)) {
            # Login name is ok
            $bug->set_assigned_to($field_value);
            $bug->update();
        }
        else {
            $vars->{errors} = "login_name: " . $field_value . " is not known to Bugzilla";
        }
    }
    elsif ($field_name eq 'priority') {
        $bug->set_priority($field_value);
        $bug->update();
    }
    elsif ($field_name eq 'bug_severity') {
        $bug->set_severity($field_value);
        $bug->update();
    }
    elsif ($field_name eq 'bug_status') {
        if ($comment_value) {
            $bug->add_comment($comment_value, {});
        }
        $bug->set_status($field_value);
        $bug->update();
    }
    else {
        $vars->{errors} = "Not able to save column " . $field_name;
    }
}

sub check_bug_status {
    my ($vars) = @_;

    my $cgi    = Bugzilla->cgi;
    my $bug_id = $cgi->param('bugid');
    my $status = $cgi->param('status');

    my $bug              = Bugzilla::Bug->new($bug_id);
    my $old_status       = $bug->status();
    my $available_states = $old_status->can_change_to();
    my $enabled          = 0;
    my $comment_required = 0;
    for my $available (@{$available_states}) {
        if ($available->name() eq $status) {
            $enabled          = 1;
            $comment_required = $available->comment_required_on_change_from($old_status);
        }
    }
    if ($enabled) {
        $vars->{ret_value} = "" . $comment_required;
    }
    else {
        $vars->{errors} = "Not able to change status from " . $old_status->name() . " to " . $status;
    }
}

1;
