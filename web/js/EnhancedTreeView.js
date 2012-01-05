/*
   The contents of this file are subject to the Mozilla Public
   License Version 1.1 (the "License"); you may not use this file
   except in compliance with the License. You may obtain a copy of
   the License at http://www.mozilla.org/MPL/
  
   Software distributed under the License is distributed on an "AS
   IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
   implied. See the License for the specific language governing
   rights and limitations under the License.
  
   The Original Code is the Enhanced Treeview Bugzilla Extension.
  
   The Initial Developer of the Original Code is "Nokia Corporation"
   Portions created by the Initial Developer are Copyright (C) 2011 the
   Initial Developer. All Rights Reserved.
  
   Contributor(s):
     Eero Heino <eero.heino@nokia.com>
  */

/**
 * Global variables
 */
var arraied = [];

function doPreToggle(elem, event)
{
    var par_li = elem.parentNode.parentNode.parentNode.parentNode.parentNode;
    doToggle(par_li, event);
    $(elem).toggleClass('b_open').toggleClass('b_closed');
}

function bindSaveButton() {
// save
    $('.save_tree').each(function ()
    {
        $(this).click(function(e)
        {
	    /**
	     * The whole tree is sent to server to be saved. It could be benefitial to
	     * separate those parts of the tree, that have changed. That has however 
	     * proved to be difficult to implement.
	     * Removing separation of changed part is fix to bug #285271
	     */
            arraied = $('ul.sortable').nestedSortable('toArray', {startDepthCount: 0});

            $.post('page.cgi?id=EnhancedTreeView_ajax.html',
                {
		    original: JSON.stringify(original_tree),
		    tree: JSON.stringify(arraied),
                }, saveResponse, 'text'); // post
	    unsaved_changes = false;
        }); // click-function
    }); // each
} // bindSaveButton

function saveResponse(response, status, xhr) 
{ 
    var retObj = eval("("+ response+")");
    if(retObj.errors)
    {
	alert(retObj.errormsg);
    }
    else
    {
        alert('Tree Saved');
        original_tree = $.extend(true, [], arraied);
        $('.edited').hide();

        // Cancel remains enabled
        $('.save_tree').attr('disabled', 'disabled');
        $('a[hrefnew]').each(function ()
        {
            elem = $(this);
            elem.attr('href', elem.attr('hrefnew'));
            elem.removeAttr('hrefnew');
        });
    }
}

function add_bug(parent_elem, html)
{
    parent_elem.append(html);
}

function ajaxify(id)
{
    var options = {
            success: function (data) { add_bug($('#children_'+id), data); },
            type: 'GET',
            target: null,
        };
    $('#create_'+id).ajaxForm(options);
}

function t_visibility(id, arg)
{
    var obj = $('#'+id);
    if (arg == 'show')
    {
        obj.show();
    } else if (arg == 'hide' && $.inArray(id, sticky) < 0)
    {
        obj.hide();
    }
}

function hide_sticky()
{
    while (sticky.length)
    {
        $(sticky.pop()).hide();
    }
}



// Evil: fix later.


// Global variables
var unsaved_changes = false;
var original_tree = [];
var edit_mode = false;
var sortable_parent = null;
var sortable_copy = false;
var sticky = [];

$(document).ready(function() {
    $('html').click(hide_sticky);

    $('.edit_mode').hide();
    $('.enable_edit_mode').each(function()
        {
            $(this).click(function()
                {
                    edit_mode = !edit_mode;
                    $('.edit_mode').toggle();
                    $('.read_mode').toggle();
                    $( ".sortable" ).sortable( "option", "disabled", false );
                });
        });


    $('.loading_element').each(function()
        {
            $(this).hide()
            .ajaxStart(function() {
                $(this).show();
            })
            .ajaxStop(function() {
                $(this).hide();
            });

        });
    $('#loadingDiv')
        .hide()  // hide it initially
        .ajaxStart(function() {
            $(this).show();
        })
        .ajaxStop(function() {
            $(this).hide();
        })
    ;

    $('.sortable').nestedSortable({
        disabled: true,
        disableNesting: 'no-nest',
        forcePlaceholderSize: true,
        handle: 'span',
        helper: 'clone',
        items: 'li',
        maxLevels: 30,
        opacity: .6,
        placeholder: 'placeholder',
        revert: 250,
        tabSize: 25,
        tolerance: 'pointer',
        toleranceElement: '> span',
        listType: 'ul',

        start: function (event, ui)
            {
                sortable_parent = ui.item.parents('li');
                // copy instead of move
                if (event.ctrlKey == true)
                {
                    //ui.item.show();
                    ui.item.clone().insertAfter(ui.item).show();
                    sortable_copy = true;
                }
            },

        stop: function (event, ui)
            {
                var done = false;
                var tree = $(this);
                var reverted = false;
                function revert()
                {
                    alert('This would cause a dependency loop');
                    tree.sortable('cancel');
                    reverted = true;
                }
                var tree_bug_ids = [];
                // dependency loop detection
                ui.item.parents('li').each(function ()
                    {
                        // detect in the same tree
                        var parent_li = $(this);
                        // bug ids above inserted element in the target tree.
                        // used to check reverse dependency in other trees
                        tree_bug_ids.push(parent_li.attr('id'));
                        ui.item.parent().find('li').each(function ()
                            {
                                if ($(this).attr('id') == parent_li.attr('id'))
                                {
                                    revert();
                                    done = true;
                                    return false;
                                }
                            });
                        if (done)
                        {
                            return false;
                        }

                        // at the top level
                        if (parent_li.parent().closest('li').attr('id') == 'foo_0')
                        {
                            var done = false;

                            var moved_bug_ids = [ui.item.attr('id')];
                            ui.item.find('li').each(function ()
                            {
                               moved_bug_ids.push($(this).attr('id'));
                            });

                            // detect other trees
                            parent_li.siblings().each(function ()
                                {
                                    var found_target_tree_bug = false;
                                    var found_target_bug = false;
                                    function check_bug(bug_id)
                                    {
                                        if ($.inArray(bug_id, tree_bug_ids) > -1)
                                        {
                                            found_target_tree_bug = true;
                                        }
                                        if ($.inArray(bug_id, moved_bug_ids) > -1)
                                        {
                                            found_target_bug = true;
                                        }
                                    }

                                    check_bug($(this).attr('id'));
                                    $(this).find('li').each(function ()
                                        {
                                            check_bug($(this).attr('id'));
                                            if (found_target_bug && found_target_tree_bug)
                                            {
                                                revert();
                                                done = true;
                                                return false;
                                            }

                                        });
                                    if (done)
                                    {
                                        return false;
                                    }

                                });
                        }
                    });

                parent_li = ui.item.parents('li');
                p_id = parent_li.attr('id');

                if (!reverted)
                {
                    $('.cancel_edit_mode').each(function ()
                    {
                        $(this).removeAttr('disabled');
                    });
                    $('.save_tree').each(function ()
                    {
                        $(this).removeAttr('disabled');
                    });
                    // replace the old parent with the new one for the clone link in all instances of this moved bug
                    $('li[id^='+ui.item.attr('id')+']').each(function ()
                    {
                        var clone_link = $(this).find('.clone_link');
                        // disabling link until saved
                        if (clone_link.attr('href') != undefined)
                        {
                            var href = clone_link.attr('href');
                            clone_link.removeAttr('href');
                        } else
                        {
                            var href = clone_link.attr('hrefnew');
                        }
                        var sortable_parent_id = sortable_parent.attr('id').replace('bug_', '');
                        var blocked_field = href.match('blocked=([0-9,]+)')
                        if (p_id == 'foo_0' || p_id == 'root' || p_id == undefined)
                        {
                            p_id = '';
                        } else
                        {
                            p_id = p_id.replace('bug_', '');
                        }
                        if (blocked_field)
                        {
                            blocked_field = blocked_field[0];
                            // copying so no need to overwrite the previous blocked
                            if (sortable_copy)
                            {
                                var new_blocked_field = blocked_field + p_id + ',';
                            } else
                            {
                                var new_blocked_field = blocked_field.replace(sortable_parent_id, p_id);
                            }
                            new_blocked_field = new_blocked_field.replace(',,', ',');
                            clone_link.attr('hrefnew', href.replace(blocked_field, new_blocked_field));
                        // didn't have a real parent until now
                        } else if (href.match('blocked=') && p_id != 'foo_0' && p_id != 'root')
                        {
                            clone_link.attr('hrefnew', href.replace('blocked=', 'blocked='+p_id));
                        }
                        if(sortable_parent_id != p_id && (sortable_parent_id != 'foo_0' || p_id != ''))
                        {
                            //alert('sortable_parent_id: '+sortable_parent_id+' p_id:'+p_id);
                            unsaved_changes = true;
                        }
                    });
                }

                sortable_copy = false;

                item_a_node = $(parent_li.find('span').find('a').get(0));
                if (p_id && p_id != 'foo_0' && p_id != 'root')
                {
                    p_id = p_id.split('_')[1];
                    item_a_node.attr('onclick', 'expclo(this);');
                    item_a_node.attr('class', 'b b_open');
                }
            }
    });

    original_tree = $('ul.sortable').nestedSortable('toArray', {startDepthCount: 0});
    bindSaveButton();

    $(window).unload(function() 
    {
        if(unsaved_changes)
        {
            if(confirm('There are unsaved changes. Changes would be lost. Save before continuing to exit?'))
            {
                $('.save_tree').each(function ()
                {
                    $(this).click();
                });
            }
        } 
    });
});
