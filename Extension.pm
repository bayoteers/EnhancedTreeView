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
# The Original Code is the TreeView Bugzilla Extension.
#
# The Initial Developer of the Original Code is Eero Heino
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Eero Heino <eero.heino@nokia.com>

package Bugzilla::Extension::TreeView;
use strict;
use base qw(Bugzilla::Extension);

# This code for this is in ./extensions/TreeView/lib/Util.pm
use Bugzilla::Extension::TreeView::Util;

our $VERSION = '0.01';

sub config {
    my ($self, $args) = @_;

    my $config = $args->{config};
    $config->{TreeView} = "Bugzilla::Extension::TreeView::Config";
}

sub config_add_panels {
    my ($self, $args) = @_;

    my $modules = $args->{panel_modules};
    $modules->{TreeView} = "Bugzilla::Extension::TreeView::Config";
}

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook"
# in the bugzilla directory) for a list of all available hooks.
sub install_update_db {
    my ($self, $args) = @_;

}

sub enter_bug_url_fields {
    my ($self, $args) = @_;
    my $vars = $args->{'vars'}; 
    my $cgi = Bugzilla->cgi;

    $vars->{'dependson'} = $cgi->param('dependson');
    $vars->{'blocks'} = $cgi->param('blocks');
    $vars->{'target_milestone'} = $cgi->param('target_milestone');
}


sub page_before_template {
    my ($self, $args) = @_;

    my ($vars, $page) = @$args{qw(vars page_id)};

    # User is stored as variable for user authorization
    $vars->{'user'} = Bugzilla->user;

    if ($page eq 'treeview.html') {
        show_tree_view($vars);
    }
    if ($page eq 'treeview_ajax.html') {
        ajax_tree_view($vars);
    }

}

__PACKAGE__->NAME;
