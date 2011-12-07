/*
   The contents of this file are subject to the Mozilla Public
   License Version 1.1 (the "License"); you may not use this file
   except in compliance with the License. You may obtain a copy of
   the License at http://www.mozilla.org/MPL/
  
   Software distributed under the License is distributed on an "AS
   IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
   implied. See the License for the specific language governing
   rights and limitations under the License.
  
   The Original Code is the Advanced Treeview Bugzilla Extension.
  
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

// This function did the job almost right.
//function expclo(node)
//{
//    var par = $(node).parent();
//    var ne_ul = par.find('ul');
//    ne_ul.toggle();
//    $(node).toggleClass('b_open').toggleClass('b_closed'); 
//}

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
