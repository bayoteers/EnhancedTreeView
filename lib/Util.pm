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
# The Initial Developer of the Original Code is YOUR NAME
# Portions created by the Initial Developer are Copyright (C) 2011 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   YOUR NAME <YOUR EMAIL ADDRESS>

package Bugzilla::Extension::TreeView::Util;
use strict;
use base qw(Exporter);

use List::Util qw(max);

our @EXPORT = qw(
  show_tree_view
  ajax_tree_view

  );

#local our $hide_resolved = $cgi->param('hide_resolved') ? 1 : 0;

#local our $maxdepth = $cgi->param('maxdepth') || 0;
local our $maxdepth      = 0;
local our $hide_resolved = 0;
if ($maxdepth !~ /^\d+$/) { $maxdepth = 0 }

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
    $realdepth = max($realdepth, $depth);

    foreach my $dep_id (@dependencies) {
        # Get this dependency's record from the database and generate
        # its sub-tree if we haven't already done so (which happens
        # when bugs appear in dependency trees multiple times).
        if (!$bugs->{$dep_id}) {
            $bugs->{$dep_id} = new Bugzilla::Bug($dep_id);
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

sub show_tree_view {
    my ($vars) = @_;
    my $cgi = Bugzilla->cgi;

    my @bug_ids = split(/[,]/, $cgi->param('bug_id'));

    $vars->{'bugs_data'} = [];

    foreach my $bug_id (@bug_ids)
    {
        my $bug = Bugzilla::Bug->check($bug_id);
        #my $bug = Bugzilla::Bug->check(scalar $cgi->param('bug_id'));
        my $id  = $bug->id;

        my $dependson_tree = { $id => $bug };
        my $dependson_ids = {};

        my %bug_data = ();

        GenerateTree($id, "dependson", 1, $dependson_tree, $dependson_ids);
        $bug_data{'dependson_tree'} = $dependson_tree;
        $bug_data{'dependson_ids'}  = [ keys(%$dependson_ids) ];

        open (MYFILE, '>>/tmp/bz.txt');
        print MYFILE "dep @{$bug_data{'dependson_ids'}} \n";

        my $blocked_tree = { $id => $bug };
        my $blocked_ids = {};
        GenerateTree($id, "blocked", 1, $blocked_tree, $blocked_ids);
        $bug_data{'blocked_tree'} = $blocked_tree;
        $bug_data{'blocked_ids'}  = [ keys(%$blocked_ids) ];

        $bug_data{'realdepth'} = $realdepth;

        $bug_data{'bugid'}         = $id;
        $bug_data{'maxdepth'}      = $maxdepth;
        $bug_data{'hide_resolved'} = $hide_resolved;

        use Storable qw(dclone);

        #my %tmp = dclone(%bug_data);
        #push (@{$vars->{'bugs_data'}}, \${bug_data} );
        push (@{$vars->{'bugs_data'}}, dclone(\%bug_data) );
        print MYFILE "dep2 @{$vars->{'bugs_data'}[0]{'dependson_ids'}} \n";

        #$vars->{'counter'} = sub { return (@_ + 1) };
    }


}

sub ajax_tree_view {
    my ($vars) = @_;

    use JSON;

    my $cgi    = Bugzilla->cgi;
    my $json = new JSON::XS;

    my $data = $cgi->param('tree');

    if ($data =~ /(.*)/) {
        $data = $1;    # $data now untainted
    }
    my $content = $json->allow_nonref->utf8->relaxed->decode($data);

    # bug id => (depends, blocks)
    my %rel_data = ();
    my %depends = ();
open (MYFILE, '>>/tmp/data.txt');
    # collect all dependecies for a bug
    for my $bug_data (@{$content})
    {
        #print MYFILE "id: ".$bug_data->{'item_id'}." parent: ".$bug_data->{'parent_id'}."\n";
        if ($bug_data->{'item_id'} ne 'root' and $bug_data->{'item_id'} ne '0' and $bug_data->{'parent_id'} ne 'root' and $bug_data->{'parent_id'} ne '0')
        {
            #print MYFILE "id: ".$bug_data->{'item_id'}." ".$bug_data->{'parent_id'}." \n";
            my $found = 0;
            foreach my $bid (keys %rel_data)
            {
                # depends on
                if($bid eq $bug_data->{'item_id'}) {
                    $found = 1;
                    push(@{$rel_data{ $bug_data->{'item_id'} }[1]}, $bug_data->{'parent_id'});
                    last;
                }
            }
            if (not $found)
            {
                @{$rel_data{ $bug_data->{'item_id'} }} = ([], [$bug_data->{'parent_id'}]);
                #@{$rel_data{ $bug_data->{'item_id'} }} = (, ($bug_data->{'parent_id'}));
            }

            $found = 0;
            foreach my $bid (keys %rel_data)
            {
                # blocks on
                if($bid eq $bug_data->{'parent_id'}) {
                    $found = 1;
                    print MYFILE "FOO @{$rel_data{ $bug_data->{'parent_id'} }[0]}\n";
                    push(@{$rel_data{ $bug_data->{'parent_id'} }[0]}, $bug_data->{'item_id'});
                    last;
                }
            }
            if (not $found)
            {
                @{$rel_data{ $bug_data->{'parent_id'} }} = ([$bug_data->{'item_id'}], []);
            }
        }
    }

#    my $dbh = Bugzilla->dbh;
#
#    $dbh->bz_start_transaction();

    for my $bid ( keys %rel_data ) {
        my (@blocks, @depends) = @{$rel_data{$bid}};

        my $bug = Bugzilla::Bug->new($bid);
        $bug->set_dependencies(@depends, @blocks);
        $bug->update();
        print MYFILE "id: ".$bid." depends @depends blocks @blocks \n";
    }

#    $dbh->bz_commit_transaction();



#    my $ordered_list     = $content->{"0"};        
#    my $counter = 1;
close (MYFILE); 
#    for my $bug_id (@{$ordered_list}) {
#        _set_bug_release_order($bug_id, $counter);
#        $msg = $msg . "bug:" . $bug_id . "," . "order:" . $counter . ";"; # DEBUG
#        $counter = $counter + 1;
#    }
#    my $unprioritised_list     = $content->{"-1"};        
#    for my $unprioritised_bug_id (@{$unprioritised_list}) {
#        _set_bug_release_order($unprioritised_bug_id, "NULL");
#        $msg = $msg . "unprioritised bug:" . $unprioritised_bug_id . ";"; # DEBUG
#    }
#
    $vars->{'json_text'} = 'hello';
    #$vars->{'json_text'} = to_json([$msg]);
}


# This file can be loaded by your extension via
# "use Bugzilla::Extension::TreeView::Util". You can put functions
# used by your extension in here. (Make sure you also list them in
# @EXPORT.)

1;
