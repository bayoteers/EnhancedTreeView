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


function expclo(node)
{
    $(node).parent().next('ul').toggle();
    $(node).toggleClass('b_open').toggleClass('b_closed'); 
}

function nrKeys(a)
{
    var i = 0;
    for (key in a)
    {
        i++;
    }
    return i;
}
function compare_associative_arrays(a, b)
{
   if (a == b)
   {
       return true;
   }   
   if (nrKeys(a) != nrKeys(b))
   {
       return false;
   }
   for (key in a)
   {     
     if (a[key] != b[key]) {
         return false;
     }
   }
   return true;
}


// save
$('.save_tree').each(function ()
{
    $(this).click(function(e)
    {
        var arraied = $('ul.sortable').nestedSortable('toArray', {startDepthCount: 0});

        var changed = [];
        var unchanged = [];

        var touched_bugs = [];
        var touched_parents = [];

        for (var i=0; i < arraied.length; i++)
        {
            var found = false;

            for (var k=0; k < original_tree.length; k++)
            {
                if (compare_associative_arrays(arraied[i], original_tree[k]))
                {
                    found = true;
                    break;
                }
            }

            if (!found)
            {
                // sending to server
                changed.push(arraied[i]);
                if ($.inArray(arraied[i]['item_id'], touched_bugs) == -1)
                {
                    touched_bugs.push(arraied[i]['item_id']);
                }
                if ($.inArray(arraied[i]['parent_id'], touched_parents) == -1)
                {
                    touched_parents.push(arraied[i]['parent_id']);
                }

            } else
            {
                unchanged.push(arraied[i]);
            }
        }

        // loop through and also send the data that didn't change for a bug that had changes
        for (var i=0; i < unchanged.length; i++)
        {
            if ($.inArray(unchanged[i]['item_id'], touched_bugs) > -1 || $.inArray(unchanged[i]['item_id'], touched_parents) > -1)
            {
                changed.push(unchanged[i]);
            }
        }

        $.post('page.cgi?id=EnhancedTreeView_ajax.html',
            {
                tree: JSON.stringify(changed),
            },
            function ()
            {
                alert('Tree Saved');
                original_tree = $.extend(true, [], arraied);
                $('.edited').hide();

                $('.cancel_edit_mode').attr('disabled', 'disabled');
                $('.save_tree').attr('disabled', 'disabled');
                $('a[hrefnew]').each(function ()
                {
                    elem = $(this);
                    elem.attr('href', elem.attr('hrefnew'));
                    elem.removeAttr('hrefnew');
                });
            },
            'json');
    });
});

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
            //beforeSubmit: function() { alert('hello'); },
            //dataType: 'null'
        };
    //bug = $('#bug_'+id+'_create');
    $('#create_'+id).ajaxForm(options);

    //create_form = $('#bug_'+id+'_create');
    //bug.hover(function (){create_form.attr('class','show');}, function() {create_form.attr('class', 'hide');}); 
     //bug.hover(function (){$('#bug_[% bug.id %]_create').show();}, function() {$('#bug_[% bug.id %]_create').hide();}) 
}

function toggle_vis(elem, id, arg)
{
    var obj = $(elem).children(id);
    if (arg == 'show')
    {
        obj.show();
    } else if (arg == 'hide' && $.inArray(id, sticky) < 0)
    {
        //alert($.inArray(elem, sticky));
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
