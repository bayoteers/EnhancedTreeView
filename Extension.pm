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

# This code for this is in ./extensions/EnhancedTreeView/lib/Util.pm
use Bugzilla::Extension::EnhancedTreeView::Util;

our $VERSION = '0.03';

sub config {
    my ($self, $args) = @_;

    my $config = $args->{config};
    $config->{EnhancedTreeView} = "Bugzilla::Extension::TreeView::Config";
}

sub config_add_panels {
    my ($self, $args) = @_;

    my $modules = $args->{panel_modules};
    $modules->{EnhancedTreeView} = "Bugzilla::Extension::TreeView::Config";
}

sub object_end_of_create {
    my ($self, $args) = @_;
    my ($class, $obj) = $args;
    
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

sub page_before_template {
    my ($self, $args) = @_;

    my ($vars, $page) = @$args{qw(vars page_id)};

    # User is stored as variable for user authorization
    $vars->{'user'} = Bugzilla->user;

    if ($page eq 'EnhancedEnhancedTreeView.html') {
        show_tree_view($vars, $VERSION);
    }
    if ($page eq 'EnhancedEnhancedTreeView_ajax.html') {
        ajax_tree_view($vars, $VERSION);
    }

}

__PACKAGE__->NAME;
