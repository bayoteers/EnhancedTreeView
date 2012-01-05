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
# The Initial Developer of the Original Code is "Nokia Corpodation"
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Heino <eero.heino@nokia.com>

package Bugzilla::Extension::EnhancedTreeView;
use strict;
use base qw(Bugzilla::Extension);

use JSON::PP;

# This code for this is in ./extensions/EnhancedTreeView/lib/Util.pm
use Bugzilla::Extension::EnhancedTreeView::Util;
use Bugzilla::Extension::EnhancedTreeView::BugRPCLib;
use Bugzilla::Extension::EnhancedTreeView::DependencyHandle;
use Bugzilla::Error;

our $VERSION = '0.03';

sub config {
    my ($self, $args) = @_;

    my $config = $args->{config};
    $config->{EnhancedTreeView} = "Bugzilla::Extension::EnhancedTreeView::Config";
}

sub config_add_panels {
    my ($self, $args) = @_;

    my $modules = $args->{panel_modules};
    $modules->{EnhancedTreeView} = "Bugzilla::Extension::EnhancedTreeView::Config";
}

sub object_end_of_create {
    my ($self,  $args) = @_;
    my ($class, $obj)  = $args;

}

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook"
# in the bugzilla directory) for a list of all available hooks.
sub install_update_db {
    my ($self, $args) = @_;

}

sub enter_bug_url_fields {
    my ($self, $args) = @_;
    my $vars = $args->{'vars'};
    my $cgi  = Bugzilla->cgi;

    $vars->{'dependson'} = $cgi->param('dependson');
    $vars->{'blocked'}   = $cgi->param('blocked');
}

sub enter_bug_url_fields_cloned {
    my ($self, $args) = @_;
    my $vars = $args->{'vars'};
    my $cgi  = Bugzilla->cgi;

    if (defined $cgi->param('dependson')) {
        $vars->{'dependson'} = $cgi->param('dependson');
    }

    if (defined $cgi->param('blocked')) {

        $vars->{'blocked'} = $cgi->param('blocked');
    }
}

sub db_schema_abstract_schema {
    my ($self, $args) = @_;

    my $schema = $args->{schema};
    $schema->{'entreeview_dependency_info'} = {
                                                FIELDS => [
                                                            blocked => {
                                                                         TYPE       => 'INT3',
                                                                         NOTNULL    => 1,
                                                                         REFERENCES => {
                                                                                         TABLE  => 'bugs',
                                                                                         COLUMN => 'bug_id',
                                                                                         DELETE => 'CASCADE'
                                                                                       }
                                                                       },
                                                            dependson => {
                                                                           TYPE       => 'INT3',
                                                                           NOTNULL    => 1,
                                                                           REFERENCES => {
                                                                                           TABLE  => 'bugs',
                                                                                           COLUMN => 'bug_id',
                                                                                           DELETE => 'CASCADE'
                                                                                         }
                                                                         },
                                                            dep_type    => { TYPE => 'INT2' },
                                                            description => { TYPE => 'varchar(127)' },
                                                          ],
                                                INDEXES => [
                                                             entreeview_dependency_info_unique_idx => {
                                                                                                        FIELDS => [qw(blocked dependson)],
                                                                                                        TYPE   => 'UNIQUE'
                                                                                                      },
                                                           ],
                                              };
}


sub fix_json {
    my $vars = shift;
    return if $vars->{json_text};
    $vars->{json_text} = JSON->new->utf8->pretty->encode({
        errors => int($vars->{errors}),
        errormsg => $vars->{errors},
        ret_value => $vars->{ret_value},
        debug_text => $vars->{debug_text}
    });
}


sub page_before_template {
    my ($self, $args) = @_;

    my ($vars, $page) = @$args{qw(vars page_id)};

    # User is stored as variable for user authorization
    $vars->{'user'} = Bugzilla->user;

    if ($page eq 'EnhancedTreeView.html') {
        _check_access_right(Bugzilla->user);
        show_tree_view($vars, $VERSION);
    }
    if ($page eq 'EnhancedTreeView_ajax.html') {
        my $cgi    = Bugzilla->cgi;
        my $schema = $cgi->param('schema');
        if ($schema eq "check_bug_status") {
            check_bug_status($vars);
        }
        elsif ($schema eq "bug") {
            update_bug_fields_from_json($vars);
        }
        elsif ($schema eq "depinfo") {
            update_dependency_info($vars);
        }
        else {
            ajax_tree_view($vars, $VERSION);
        }
        fix_json($vars);
    }
    #if ($page eq 'EnhancedTreeView_create_bug.html')
    if ($page eq 'EnhancedTreeView_display_tree.html') {
        ajax_create_bug($vars);
    }

}

sub template_before_process {
    my ($self, $args) = @_;

    my $vars = $args->{vars};
    $vars->{treeviewurl} = "page.cgi?id=EnhancedTreeView.html";
}

sub _check_access_right {
    my ($user) = @_;

    my $has_access    = 0;
    my $named_group   = "";
    my $access_groups = Bugzilla->params->{'enhancedtreeview_access_groups'};
    for my $et_group (@{$access_groups}) {
        if ($user->in_group($et_group)) {
            $has_access = 1;
        }
        if ($named_group ne "") {
            $named_group .= ", ";
        }
        $named_group .= $et_group;
    }

    if (not $has_access) {
        ThrowUserError('auth_failure', { group => $named_group, action => "access", object => "enhancedtree" });
    }
}

sub bug_end_of_update {
    my ($self, $args) = @_;

    my ($bug, $old_bug, $timestamp, $changes) = @$args{qw(bug old_bug timestamp changes)};

    my @all_changed_fields = keys %{$changes};
    if (grep { $_ eq "blocked" } @all_changed_fields) {
        my $bug_id = $bug->id();

        my $dbh = Bugzilla->dbh;
        my $sth = $dbh->prepare(
            'select 
	    einfo.blocked
        from 
	    entreeview_dependency_info einfo 
        where 
	    einfo.dependson = ? and 
        not exists 
        (select 
	    null 
        from 
	    dependencies dep 
        where 
	    dep.blocked = einfo.blocked and 
	    dep.dependson = ?)'
                               );
        $sth->execute($bug_id, $bug_id);
        my $removed_blocked;
        while (($removed_blocked) = $sth->fetchrow_array()) {
            $dbh->do('DELETE FROM entreeview_dependency_info WHERE blocked = ? AND dependson = ?', undef, $removed_blocked, $bug_id);
        }
    }

    if (grep { $_ eq "dependson" } @all_changed_fields) {
        my $bug_id = $bug->id();

        my $dbh = Bugzilla->dbh;
        my $sth = $dbh->prepare(
            'select 
	    einfo.dependson
        from 
	    entreeview_dependency_info einfo 
        where 
	    einfo.blocked = ? and 
        not exists 
        (select 
	    null 
        from 
	    dependencies dep 
        where 
	    dep.dependson = einfo.dependson and 
	    dep.blocked = ?)'
                               );
        $sth->execute($bug_id, $bug_id);
        my $removed_dependson;
        while (($removed_dependson) = $sth->fetchrow_array()) {
            $dbh->do('DELETE FROM entreeview_dependency_info WHERE blocked = ? AND dependson = ?', undef, $bug_id, $removed_dependson);
        }
    }
}
__PACKAGE__->NAME;
