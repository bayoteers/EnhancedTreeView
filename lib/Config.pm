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

package Bugzilla::Extension::EnhancedTreeView::Config;
use strict;
use warnings;

use Bugzilla::Config::Common;

sub get_param_list {
    my ($class) = @_;

    my @param_list = (
                      {
                         name    => 'enhancedtreeview_inherited_attributes',
                         desc    => 'Create bug: inherited options from the depends on bug',
                         type    => 'm',
                         choices => [ 'assigned_to', 'bug_severity', 'rep_platform' ],
                         default => []
                      },
                      {
                         name    => 'enhancedtreeview_use_scrums_extension',
                         desc    => 'Use Scrums extension for creation of bugs to put them to the parents sprint',
                         type    => 'b',
                         default => 0
                      },
                      {
                         name    => 'enhancedtreeview_mail_notifications',
                         desc    => 'Send email notifications about dependency changes to users',
                         type    => 'b',
                         default => 1
                      },
                      {
                         name    => 'enhancedtreeview_access_groups',
                         desc    => 'Groups that are allowed to use EnhancedTreeView.',
                         type    => 'm',
                         choices => \&_get_all_group_names,
                         default => ['admin'],
                      },
                      {
                         name    => 'enhancedtreeview_highlighted_item_types',
                         desc    => 'List of severities of those bugs, that are highlighted in tree view.',
                         type    => 'm',
                         choices => [ 'blocker', 'change_request', 'critical', 'feature', 'major', 'minor', 'normal', 'task', 'story' ],
                         default => [ 'story' ]
                      },
                     );
    return @param_list;
}

sub _get_all_group_names {
    my @group_names = map { $_->name } Bugzilla::Group->get_all;
    unshift(@group_names, '');

    my @sorted = sort { lc $a cmp lc $b } @group_names;

    return \@sorted;
}

1;
