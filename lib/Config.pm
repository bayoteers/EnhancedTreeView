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


package Bugzilla::Extension::TreeView::Config;
use strict;
use warnings;


use Bugzilla::Config::Common;

sub get_param_list {
    my ($class) = @_;

    my @param_list = (
                      {
                         name    => 'treeview_inherited_attributes',
                         desc    => 'Create bug: inherited options from the depends on bug',
                         type    => 'm',
                         choices => ['assigned_to', 'bug_severity', 'rep_platform'],
                         default => []
                       }
                     );
    return @param_list;
}

1;