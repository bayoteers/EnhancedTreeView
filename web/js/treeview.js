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
        function () { alert('saved'); },
        'json');
});


