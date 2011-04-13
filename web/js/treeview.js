function doToggle_with_ol(node, event) {
    var deep = event.altKey || event.ctrlKey;

    if (node.nodeType == Node.TEXT_NODE)
        node = node.parentNode;

    var toggle = node.nextSibling;
    while (toggle && toggle.tagName != "OL")
        toggle = toggle.nextSibling;

    if (toggle) {
        if (deep) {
            var direction = toggleDisplay(toggle, $(node).children('a').get(0));
            changeChildren(toggle, direction);
        } else {
            toggleDisplay(toggle, $(node).children('a').get(0));
        }
    }
    /* avoid problems with default actions on links (mozilla's
     * ctrl/shift-click defaults, for instance */
    event.preventBubble();
    event.preventDefault();
    return false;
}

// save
$('#save_tree').click(function(e)
{
    arraied = $('ol.sortable').nestedSortable('toArray', {startDepthCount: 0});
    //alert('puuhp');

    $.post('page.cgi?id=treeview_ajax.html',
        {
            tree: JSON.stringify(arraied),
        },
        function () { alert('saved'); },
        'json');

//        schema: schema,
//        action: 'set',
//        obj_id: obj_id,
//        data: JSON.stringify(data_lists)
//    arraied = dump(arraied);
//    (typeof($('#toArrayOutput')[0].textContent) != 'undefined') ?
//    $('#toArrayOutput')[0].textContent = arraied : $('#toArrayOutput')[0].innerText = arraied;
});

