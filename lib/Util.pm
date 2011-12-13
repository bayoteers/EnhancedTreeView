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
# The Original Code is the Advanced Treeview Bugzilla Extension.
#
# The Initial Developer of the Original Code is "Nokia Corporation"
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Heino <eero.heino@nokia.com>

package Bugzilla::Extension::EnhancedTreeView::Util;
use strict;
use base qw(Exporter);

use Bugzilla::Extension::EnhancedTreeView::DependencyHandle;
use List::Util qw(max);
use JSON;
use Storable qw(dclone);

our @EXPORT = qw(
  show_tree_view
  ajax_tree_view
  ajax_create_bug
  );

local our $maxdepth      = 0;
local our $hide_resolved = 0;
if ($maxdepth !~ /^\d+$/) { $maxdepth = 0; }

################################################################################
# Main Section                                                                 #
################################################################################

# Stores the greatest depth to which either tree goes.
local our $realdepth = 0;

sub GenerateTree {
    # Generates a dependency tree for a given bug.  Calls itself recursively
    # to generate sub-trees for the bug's dependencies.
    my ($bug_id, $relationship, $depth, $bugs, $ids) = @_;

    my @dependencies;
    if ($relationship eq 'dependson') {
        @dependencies = @{ $bugs->{$bug_id}->dependson };
    }
    else {
        @dependencies = @{ $bugs->{$bug_id}->blocked };
    }

    # Don't do anything if this bug doesn't have any dependencies.
    return unless scalar(@dependencies);

    # Record this depth in the global $realdepth variable if it's farther
    # than we've gone before.
    if (!$depth) {
        $depth = 0;
    }
    if (!$realdepth) {
        $realdepth = 0;
    }
    $realdepth = max($realdepth, $depth);

    foreach my $dep_id (@dependencies) {
        # Get this dependency's record from the database and generate
        # its sub-tree if we haven't already done so (which happens
        # when bugs appear in dependency trees multiple times).
        if (!$bugs->{$dep_id}) {
            $bugs->{$dep_id} = new Bugzilla::Bug($dep_id);
            #%{$bugs->{$dep_id}->{'af'}} = \$bugs->{$dep_id}->fields();
            GenerateTree($dep_id, $relationship, $depth + 1, $bugs, $ids);
        }

        # Add this dependency to the list of this bug's dependencies
        # if it exists, if we haven't exceeded the maximum depth the user
        # wants the tree to go, and if the dependency isn't resolved
        # (if we're ignoring resolved dependencies).
        if (   !$bugs->{$dep_id}->{'error'}
            && Bugzilla->user->can_see_bug($dep_id)
            && (!$maxdepth || $depth <= $maxdepth)
            && ($bugs->{$dep_id}->isopened || !$hide_resolved)) {
            # Due to AUTOLOAD in Bug.pm, we cannot add 'dependencies'
            # as a bug object attribute from here.
            push(@{ $bugs->{'dependencies'}->{$bug_id} }, $dep_id);
            $ids->{$dep_id} = 1;
        }
    }
}

sub get_bug_data {
    my ($bug_id, $get_deps) = @_;
    my $cgi = Bugzilla->cgi;

    my $bug = Bugzilla::Bug->check($bug_id);
    my $id  = $bug->id;

    my $dependson_tree = { $id => $bug };
    my $dependson_ids = {};

    my %bug_data = ();

    if ($get_deps) {
        GenerateTree($id, "dependson", 1, $dependson_tree, $dependson_ids);
    }
    $bug_data{'dependson_tree'} = $dependson_tree;
    $bug_data{'dependson_ids'}  = [ keys(%$dependson_ids) ];

    my $blocked_tree = { $id => $bug };
    my $blocked_ids = {};
    if ($get_deps) {
        GenerateTree($id, "blocked", 1, $blocked_tree, $blocked_ids);
    }
    $bug_data{'blocked_tree'} = $blocked_tree;
    $bug_data{'blocked_ids'}  = [ keys(%$blocked_ids) ];

    my $tree_blocked_info = {};

    get_blocked_info($tree_blocked_info, $dependson_ids);
    $bug_data{'blocked_info'} = $tree_blocked_info;

    $bug_data{'bugid'}         = $id;
    $bug_data{'maxdepth'}      = $maxdepth;
    $bug_data{'hide_resolved'} = $hide_resolved;
    $bug_data{'allfields'}     = $bug->fields();
    return \%bug_data;
}

sub show_tree_view {
    my ($vars, $VERSION) = @_;
    my $cgi = Bugzilla->cgi;

    $vars->{'version'} = $VERSION;

    my @bug_ids = split(/[,]/, $cgi->param('bug_id'));

    local our $hide_resolved = $cgi->param('hide_resolved') ? 1 : 0;

    $vars->{'inherited_fields'} = Bugzilla->params->{"enhancedtreeview_inherited_attributes"};

    $vars->{'hide_resolved'} = $hide_resolved;

    $vars->{'bug_id_list'} = $cgi->param('bug_id');

    local our $maxdepth = $cgi->param('maxdepth') || 0;

    $vars->{'bugs_data'} = [];

    foreach my $bug_id (@bug_ids) {
        push(@{ $vars->{'bugs_data'} }, get_bug_data($bug_id, 1));
    }
    $vars->{'realdepth'} = $realdepth;
    $vars->{'maxdepth'}  = $maxdepth;
}

sub transform_hw {
    # To handle multiple value rep_platform

    my $ts = "0,";
    my $g;

    foreach my $t (@_) {
        $ts .= $t . ",";
        $g = $t;
    }

    $ts .= "0";

    if (($ts =~ tr/,//) <= 2) {
        return $g;
    }
    else {
        return $ts;
    }
}

sub ajax_create_bug {
    use Bugzilla::Constants;

    my ($vars) = @_;
    my $cgi = Bugzilla->cgi;

    my $new_hw = transform_hw($cgi->param('rep_platform'));

    # Group Validation
    my @selected_groups;
    foreach my $group (grep(/^bit-\d+$/, $cgi->param())) {
        $group =~ /^bit-(\d+)$/;
        push(@selected_groups, $1);
    }

    # The format of the initial comment can be structured by adding fields to the
    # enter_bug template and then referencing them in the comment template.
    #    my $format = $template->get_format("bug/create/comment",
    #                                       scalar($cgi->param('format')), "txt");
    #    $template->process($format->{'template'}, $vars, \$comment)
    #        || ThrowTemplateError($template->error());

    # Include custom fields editable on bug creation.
    my @custom_bug_fields = grep { $_->type != FIELD_TYPE_MULTI_SELECT && $_->enter_bug } Bugzilla->active_custom_fields;

    # Undefined custom fields are ignored to ensure they will get their default
    # value (e.g. "---" for custom single select fields).
    my @bug_fields = grep { defined $cgi->param($_->name) } @custom_bug_fields;
    @bug_fields = map { $_->name } @bug_fields;

    push(
        @bug_fields, qw(
          product
          component

          assigned_to
          qa_contact

          alias
          blocked
          commentprivacy
          bug_file_loc
          bug_severity
          bug_status
          dependson
          keywords
          short_desc
          op_sys
          priority
          rep_platform
          version
          target_milestone
          status_whiteboard

          estimated_time
          deadline
          )
        );
    my %bug_params;
    foreach my $field (@bug_fields) {
        $bug_params{$field} = $cgi->param($field);

        if ($field eq "rep_platform") {
            $bug_params{$field} = $new_hw;
        }
        else {
            $bug_params{$field} = $cgi->param($field);
        }
    }
    $bug_params{'cc'}      = [ $cgi->param('cc') ];
    $bug_params{'groups'}  = \@selected_groups;
    $bug_params{'comment'} = $cgi->param('comment');

    my @multi_selects = grep { $_->type == FIELD_TYPE_MULTI_SELECT && $_->enter_bug } Bugzilla->active_custom_fields;

    foreach my $field (@multi_selects) {
        $bug_params{ $field->name } = [ $cgi->param($field->name) ];
    }

    my $bug = Bugzilla::Bug->create(\%bug_params);

    #my %bug_data;
    #$bug_data{'id'} = $bug->bug_id;
    #$vars->{'json_text'} = to_json(\%bug_data);

    push(@{ $vars->{'bugs_data'} }, get_bug_data($bug->bug_id, 0));
}

sub ajax_tree_view {
    my ($vars) = @_;

    my $cgi  = Bugzilla->cgi;
    my $dbh  = Bugzilla->dbh;
    my $json = new JSON::XS;

    my $original_data = $cgi->param('original');

    if ($original_data =~ /(.*)/) {
        $original_data = $1;    # $data now untainted
    }
    my $original = $json->allow_nonref->utf8->relaxed->decode($original_data);
    my %original_rel_data;
    parse_relations_from_array($original, \%original_rel_data);
    my $comp_err = compare_original_to_database(\%original_rel_data);

    if ($comp_err) {
        $vars->{'errors'} = "Collision in database update. Refresh page to update data.";
        return;
    }

    my $data = $cgi->param('tree');

    if ($data =~ /(.*)/) {
        $data = $1;    # $data now untainted
    }
    my $content = $json->allow_nonref->utf8->relaxed->decode($data);

    my %rel_data;
    my $rel_data_ref = \%rel_data;
    parse_relations_from_array($content, $rel_data_ref);

    my $mail_delivery_method = '';
    if (Bugzilla->params->{"enhancedtreeview_mail_notifications"}) {
        # Old mail_delivery_method choices contained no uppercase characters
        if (exists Bugzilla->params->{'mail_delivery_method'}
            && Bugzilla->params->{'mail_delivery_method'} !~ /[A-Z]/) {
            $mail_delivery_method = Bugzilla->params->{'mail_delivery_method'};
            Bugzilla->params->{'mail_delivery_method'} = 'None';
        }
    }

    $dbh = Bugzilla->dbh;
    $dbh->bz_start_transaction();
    my @all_bugs = keys %rel_data;
    for my $bid (@all_bugs) {
        my (@blocks, @depends) = @{ $rel_data_ref->{$bid} };

        if (@depends and (scalar $depends[0] == 0 or $depends[0] == 'root')) {
            @depends = [];
        }
        my $bug = Bugzilla::Bug->new($bid);
        $bug->set_dependencies(@depends, @blocks);
        use Data::Dumper;

        $bug->update();
    }
    $dbh->bz_commit_transaction();

    if (Bugzilla->params->{"enhancedtreeview_mail_notifications"}) {
        if (exists Bugzilla->params->{'mail_delivery_method'}
            && Bugzilla->params->{'mail_delivery_method'} !~ /[A-Z]/) {
            Bugzilla->params->{'mail_delivery_method'} = $mail_delivery_method;
        }
    }

    #    $vars->{'json_text'} = 'hello';
}

sub parse_relations_from_array {
    my ($content, $rel_data) = @_;

    # collect all dependecies for a bug
    for my $bug_data (@{$content}) {
        #  and $bug_data->{'parent_id'} ne 'root'
        if ($bug_data->{'item_id'} ne 'root' and $bug_data->{'item_id'} ne '0') {
            my $found = 0;
            foreach my $bid (keys %{$rel_data}) {
                # depends on
                if ($bid eq $bug_data->{'item_id'}) {
                    $found = 1;
                    my $parent_relations = $rel_data->{ $bug_data->{'item_id'} }[1];
                    my $bug_parent_id    = $bug_data->{'parent_id'};
                    if (not grep { $_ eq $bug_parent_id } @{$parent_relations}) {
                        push @{$parent_relations}, $bug_parent_id;
                    }
                    last;
                }
            }
            if (not $found) {
                @{ $rel_data->{ $bug_data->{'item_id'} } } = ([], [ $bug_data->{'parent_id'} ]);
            }

            if ($bug_data->{'parent_id'} ne '0' and $bug_data->{'parent_id'} ne 'root') {
                $found = 0;
                foreach my $bid (keys %{$rel_data}) {
                    # blocks on
                    if ($bid eq $bug_data->{'parent_id'}) {
                        $found = 1;
                        my $dependent_relations = $rel_data->{ $bug_data->{'parent_id'} }[0];
                        my $bug_dependent_id    = $bug_data->{'item_id'};
                        if (not grep { $_ eq $bug_dependent_id } @{$dependent_relations}) {
                            push @{$dependent_relations}, $bug_dependent_id;
                        }
                        last;
                    }
                }
                if (not $found) {
                    @{ $rel_data->{ $bug_data->{'parent_id'} } } = ([ $bug_data->{'item_id'} ], []);
                }
            }
        }
    }
}

sub compare_original_to_database {
    my ($original_rel_data) = @_;
    my $different           = 0;
    my @processed_bugs      = keys %{$original_rel_data};
    for my $bug_id (@processed_bugs) {

        my ($original_dependson, $original_blocked) = @{ $original_rel_data->{$bug_id} };

        my $bug               = Bugzilla::Bug->check($bug_id);
        my $current_dependson = $bug->dependson;
        my $current_blocked   = $bug->blocked;

        my @temp_array;
        for my $item (@{$current_blocked}) {
            if (grep { $_ eq $item } @processed_bugs) {
                push @temp_array, $item;
            }
        }
        @{$current_blocked} = @temp_array;
        @{$original_blocked} = grep { $_ != 0 } @{$original_blocked};
        if (scalar @{$current_dependson} != scalar @{$original_dependson}) {
            $different = 1;
        }
        else {
            for my $currentid (@{$current_dependson}) {
                if (not grep { $_ eq $currentid } @{$original_dependson}) {
                    $different = 1;
                }
            }
        }
        if (scalar @{$current_blocked} != scalar @{$original_blocked}) {
            $different = 1;
        }
        else {
            for my $currentid (@{$current_blocked}) {
                if (not grep { $_ eq $currentid } @{$original_blocked}) {
                    $different = 1;
                }
            }
        }
    }
    return $different;
}

1;
