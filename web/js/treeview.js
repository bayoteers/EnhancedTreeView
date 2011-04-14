function expclo(node)
{
    $(node).parent().next('ul').toggle();
    $(node).toggleClass('b_open').toggleClass('b_closed'); 
}

// save
$('#save_tree').click(function(e)
{
    arraied = $('ul.sortable').nestedSortable('toArray', {startDepthCount: 0});

    $.post('page.cgi?id=treeview_ajax.html',
        {
            tree: JSON.stringify(arraied),
        },
        function () { alert('saved'); },
        'json');
});

