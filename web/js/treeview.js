/*
   The contents of this file are subject to the Mozilla Public
   License Version 1.1 (the "License"); you may not use this file
   except in compliance with the License. You may obtain a copy of
   the License at http://www.mozilla.org/MPL/
  
   Software distributed under the License is distributed on an "AS
   IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
   implied. See the License for the specific language governing
   rights and limitations under the License.
  
   The Original Code is the TreeView Bugzilla Extension.
  
   The Initial Developer of the Original Code is Eero Heino
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
$('#save_tree').click(function(e)
{
    var arraied = $('ul.sortable').nestedSortable('toArray', {startDepthCount: 0});

    var changed = [];

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
            changed.push(arraied[i]);
        }
    }

    $.post('page.cgi?id=treeview_ajax.html',
        {
            tree: JSON.stringify(changed),
        },
        function ()
        {
            alert('saved'); original_tree = $.extend(true, [], arraied); $('.edited').hide();

            $('#cancel_edit_mode').attr('disabled', 'disabled');
            $('#save_tree').attr('disabled', 'disabled');
        },
        'json');
});


