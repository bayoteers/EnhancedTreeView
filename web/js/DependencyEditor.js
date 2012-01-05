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
     Visa Korhonen <visa.korhonen@symbio.com>
     David Wilson <dw@botanicus.net>
  */

var DependencyEditor = {
    /**
     * Initialize the object and install our (bubbling) onblur handler.
     */
    init: function()
    {
        this.state = null;
        $(document).focusout(this._onFocusOut.bind(this));
    },

    /**
     * Respond to any element losing focus by 
     */
    _onFocusOut: function(event)
    {
        var sensitive = { description: 1, deptypesel: 1 };
        if(! (sensitive[event.target.id] && this.state)) {
            return;
        }

        var confirmMsg = "Do you want to save description of dependence?";
        if(this.isDirty() && confirm(confirmMsg)) {
            this.save();
        } else {
            this.hide();
        }
    },

    /**
     * Render the editor and insert it into the DOM.
     */
    _render: function()
    {
        var state = this.state;
        var template = $('#desc_row_template').clone();

        $('#deptypesel', template).val(state.dep_type);
        $('#description', template).val(state.description);
        $('#blocked_bugid', template).val(state.blocked);
        $('#dependson_bugid', template).val(state.dependson);
        $('span[title=cancel]', template).click(this.hide.bind(this));
        $('span[title=save]', template).click(this.save.bind(this));
        state.template = template;

        var elem = $('#dep_' + state.blocked + '_' + state.dependson);
        elem.parent().after(template);
        $("#description", template).focus();
    },

    /**
     * @param blocked
     *      Integer ID of the blocked bug in this relation ("parent bug").
     * @param dependson
     *      Integer ID of the depended-on bug in this relation ("child bug").
     * @param description
     *      String dependency description.
     * @param dep_type
     *      Integer dependency type (see deptypesel in
     *      EnhancedTreeView.html.tmpl)..
     */
    show: function(blocked, dependson, description, dep_type)
    {
        this.hide();

        this.state = {
            blocked: blocked, // renamed: blocked_bugid
            dependson: dependson, // renamed: dependson_bugid
            description: description,
            dep_type: dep_type // renamed: type_value
        };

        // Stash a string copy of state away later to compare with form to
        // see if it changed.
        this.state.origParams = $.param(this.state);

        this._render();
    },

    /**
     * Hide the editor if visible, and discard any state.
     */
    hide: function()
    {
        if(this.state) {
            this.state.template.remove();
            this.state = null;
        }
    },

    /**
     * Return an object containing parameters describing the dependency.
     */
    getParams: function()
    {
        return {
            blocked: this.state.blocked,
            dependson: this.state.dependson,
            description: $('#description', this.state.template).val(),
            deptype: $('#deptypesel', this.state.template).val()
        };
    },

    /**
     * Return true if editor is currently visible and the form has been
     * modified by the user.
     */
    isDirty: function()
    {
        var state = this.state;
        return state && $.param(this.getParams()) != state.origParams;
    },

    /**
     * Saves dependency description into database using AJAX call.
     */
    save: function()
    {
        if(! this.isDirty()) {
            return;
        }

        $.post('page.cgi?id=EnhancedTreeView_ajax.html', {
            schema: 'depinfo',
            action: 'update',
            data: JSON.stringify({
                id: 0,
                method: "Depinfo.update",
                params: this.getParams()
            })
        }, this._onSaveDone.bind(this), 'text');
    },

    /**
     * Callback invoked after succesfull AJAX call if succesfull, if server
     * responds without throwing exception. Ordered errors are shown in error
     * message. Function shows status of saving to user.
     */
    _onSaveDone: function(response, status, xhr)
    {
        var retObj = $.parseJSON(response);
        if (retObj.errors) {
            alert("There are errors: " + retObj.errormsg);
        } else {
            alert("Success");
            window.location.reload();
        }
    }
};
