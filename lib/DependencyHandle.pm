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
  get_dependency_info
  update_dependency_info
  );

sub handle_removed_dependency {
    my ($vars) = @_;

    my $cgi = Bugzilla->cgi;
    my $dbh = Bugzilla->dbh;

    #    $vars->{'json_text'} = 'hello';
}

sub get_dependency_info {
    my ($tree_dependency_info, $dep_ids) = @_;

    my $dbh = Bugzilla->dbh;
    my @ids = keys %{$dep_ids};

    if (scalar @ids == 0) {
        return;
    }

    my $id_str = "";
    for my $id (@ids) {
        if ($id_str ne "") {
            $id_str .= ", ";
        }
        $id_str .= "$id";
    }
    my $query_str = 'select 
            blocked,
            dependson,
            dep_type,
            description
        from 
            entreeview_dependency_info 
        where 
            dependson in (' . $id_str . ')';
    my $sth = $dbh->prepare($query_str);
    $sth->execute();
    my ($blocked, $dependson, $dep_type, $description);

    while (($blocked, $dependson, $dep_type, $description) = $sth->fetchrow_array()) {
        if ($dep_type == undef) {
            $dep_type = 0;
        }
        my @info = ($description, $dep_type);
        if (!$tree_dependency_info->{$dependson}) {
            $tree_dependency_info->{$dependson} = {};
        }
        $tree_dependency_info->{$dependson}->{$blocked} = \@info;
    }
}

sub update_dependency_info {
    my ($vars) = @_;

    my $data = Bugzilla->cgi->param('data');
    if ($data =~ /(.*)/) {
        $data = $1;    # $data now untainted
    }

    my $json = new JSON::XS;
    my $content = $json->allow_nonref->utf8->decode($data);
    my $params = $content->{params};

    my $affected = Bugzilla->dbh->do(
        'UPDATE entreeview_dependency_info '.
        'SET description = ?, dep_type = ? '.
        'WHERE blocked = ? AND dependson = ?', undef,
        $params->{description}, $params->{deptype},
        $params->{blocked}, $params->{dependson});

    if($affected <= 0) {
        Bugzilla->dbh->do(
            'INSERT INTO entreeview_dependency_info'.
                '(blocked, dependson, description, dep_type)'.
            'VALUES (?, ?, ?, ?)', undef,
            $params->{blocked}, $params->{dependson},
            $params->{description}, $params->{deptype});
    }
}

1;
