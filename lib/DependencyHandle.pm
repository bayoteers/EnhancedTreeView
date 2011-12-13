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
#   Visa Korhonen <visa.korhonen@symbio.com>

package Bugzilla::Extension::EnhancedTreeView::DependencyHandle;
use strict;
use base qw(Exporter);

our @EXPORT = qw(
  handle_removed_dependency
  get_blocked_info
  );

sub handle_removed_dependency {
    my ($vars) = @_;

    my $cgi = Bugzilla->cgi;
    my $dbh = Bugzilla->dbh;

    #    $vars->{'json_text'} = 'hello';
}

sub get_blocked_info {
    my ($tree_blocked_info, $dep_ids) = @_;

    my $dbh = Bugzilla->dbh;           
    my @ids = keys %{$dep_ids};
    my $id_str = "";
    for my $id (@ids) {
        if($id_str ne "") {
            $id_str .= ", ";
        }
        $id_str .= "$id";
    }
    my $sth = $dbh->prepare(
        'select 
            blocked,
            dependson,
            description
        from 
            entreeview_dependency_info 
        where 
            dependson in (?)');
    $sth->execute($id_str);
    my ($blocked, $dependson, $description);
    while (($blocked, $dependson, $description) = $sth->fetchrow_array) {
        if (!$tree_blocked_info->{$dependson}) {
            $tree_blocked_info->{$dependson} = {};
        }
        $tree_blocked_info->{$dependson}->{$blocked} = $description;
    }
}

1;
