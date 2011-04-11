function doToggle_with_ol(node, event) {
    var deep = event.altKey || event.ctrlKey;

    if (node.nodeType == Node.TEXT_NODE)
        node = node.parentNode;

    var toggle = node.nextSibling;
    while (toggle && toggle.tagName != "OL")
        toggle = toggle.nextSibling;

    if (toggle) {
        if (deep) {
            var direction = toggleDisplay(toggle, node);
            changeChildren(toggle, direction);
        } else {
            toggleDisplay(toggle, node);
        }
    }
    /* avoid problems with default actions on links (mozilla's
     * ctrl/shift-click defaults, for instance */
    event.preventBubble();
    event.preventDefault();
    return false;
}

