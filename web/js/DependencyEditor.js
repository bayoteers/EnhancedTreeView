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
  */

  var description_editable = false;
  var cancelButton = false;
  var saveButton = false;
  var originalSelectedIndex = 0;

  function makeDependencyInfoEditable(blocked_bugid, dependson_bugid, desc_value, type_value) {
      if(description_editable) {
          makeDescriptionStatic();
          description_editable = false;
          return;
      }
      var elem = $('#dep_' + blocked_bugid + '_' + dependson_bugid);
      var par = elem[0].parentNode;
      $(par).after(getEditableDependencyInfoHtml(blocked_bugid, dependson_bugid, desc_value));
      var sel_elem = $("#deptypesel");
      originalSelectedIndex = type_value;
      sel_elem[0].selectedIndex = type_value;
      $("#description").focus();
      description_editable = true;
  }

  $(document).ready(putHandler);

  function putHandler() {
      $("*").focus(indicateFocus);
  }

  function indicateFocus(event) {
      var x=event.target; 
      if(x.id != "description" && x.id != "deptypesel") {
          makeDescriptionStatic();
      }
  }

  function getEditableDependencyInfoHtml(blocked_bugid, dependson_bugid, desc_value)
  {
      var template = $('#desc_row_template').clone();
      $('#description', template).val(desc_value);
      $('#blocked_bugid', template).val(blocked_bugid);
      $('#dependson_bugid', template).val(dependson_bugid);
      return template;
  }

  function makeDescriptionStatic() {
      var elem = $("#description");
      var text = elem[0].value;
      var original = elem[0].defaultValue;

      var sel = $("#deptypesel");
      var selectedIndex = sel[0].selectedIndex;

      if(text != original || selectedIndex != originalSelectedIndex) {
          if(saveButton) {
              saveDepDescription(text, selectedIndex);
          }
          else if(!cancelButton) {
              if(confirm("Do you want to save description of dependence?")) {
                  saveDepDescription(text, selectedIndex);
              }
          }
      }
      elem = $("#desc_row").remove();

      saveButton = false;
      cancelButton = false;
      description_editable = false;
  }

  /**
   * Function saves value of dependency description into database by doing ajax-call.
   */

  function saveDepDescription(newValue, newSelection) {
      var elem = $("#description");
      var text = elem[0].value;

      elem = $("#blocked_bugid");
      var blocked_bugid = elem[0].value;
      elem = $("#dependson_bugid");
      var dependson_bugid = elem[0].value;

    var json_params = '{ "method": "Depinfo.update", "params": { "blocked" : "' + blocked_bugid + 
	'", "dependson" : "' + dependson_bugid + '", "description" : "' + newValue + 
	'", "deptype" : "' + newSelection + '"}, "id" : 0 }';
  
    $.post('page.cgi?id=EnhancedTreeView_ajax.html', {
      schema: 'depinfo',
      action: 'update',
      data: json_params
    }, saveDepResponse, 'text');
  }

  /**
   * Function is call-back function, that is called after succesfull ajax call returns.
   * Ajax call if succesfull, if server responds without throwing exception. Ordered
   * errors are shown in error message. Function shows status of saving to user.
   */
  
  function saveDepResponse(response, status, xhr) {
    var retObj = eval("(" + response + ")");

    if (retObj.errors) {
      alert("There are errors: " + retObj.errormsg);
    } else {
      window.location.reload();
      alert("Success");
    }
  }

