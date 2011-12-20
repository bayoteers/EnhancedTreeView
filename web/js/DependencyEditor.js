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

  function makeDependencyInfoEditable(blocked_bugid, dependson_bugid, desc_value) {
      if(description_editable) {
          makeDescriptionStatic();
          description_editable = false;
          return;
      }
      var elem = $('#dep_' + blocked_bugid + '_' + dependson_bugid);
      var par = elem[0].parentNode;
      $(par).after(getEditableDependencyInfoHtml(blocked_bugid, dependson_bugid, desc_value));
      $("#description").focus();
      description_editable = true;
  }

  $(document).ready(putHandler);

  function putHandler() {
      //$("*").blur(indicateBlur);
      $("*").focus(indicateFocus);
  }

//  function indicateBlur(event) {
//      var x=event.target; 
//  }

  function indicateFocus(event) {
      var x=event.target; 
      if(x.id != "description" && x.id != "deptypesel") {
          makeDescriptionStatic();
      }
  }

  function getEditableDependencyInfoHtml(blocked_bugid, dependson_bugid, desc_value) {
      var str = '<tr id="desc_row">' +
                  '<td colspan="4">' +
                    '<table>' +
                      '<tr>' +
                        '<td>' +
                          '<textarea rows="4" cols="30" id="description">' +
                            desc_value +
                          '</textarea><br>' +
                          '<select id="deptypesel">' +
                            '<option value="0">undefined</option>' +
                            '<option value="1">blocking</option>' +
                          '</select>' +
                        '</td>' +
                        '<td onmouseover="cancelButton = true;" onmouseout="cancelButton = false;" onclick="makeDescriptionStatic();">' +
        	          '<span class="ui-icon ui-icon-arrowreturnthick-1-w" title="cancel"></span>' +
	                '</td>' +
	                '<td onmouseover="saveButton = true;" onmouseout="saveButton = false;" onclick="makeDescriptionStatic();">' +
	                  '<span class="ui-icon ui-icon-check" title="save"></span>' +
	                '</td>' +
                        '<td>' +
                           '<input type="hidden" id="blocked_bugid" value="' + blocked_bugid + '"/>' +
                           '<input type="hidden" id="dependson_bugid" value="' + dependson_bugid + '"/>' +
	                '</td>' +
                      '</tr>' +
                   '</table>' +
                 '</td>' +
               '</tr>';
      return str;
  }

  function makeDescriptionStatic() {
      var elem = $("#description");
      var text = elem[0].value;
      var original = elem[0].defaultValue;

      if(text != original) {
          if(saveButton) {
              saveDepDescription(text);
          }
          else if(!cancelButton) {
              if(confirm("Do you want to save description of dependence?")) {
                  saveDepDescription(text);
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

  function saveDepDescription(newValue) {
      var elem = $("#description");
      var text = elem[0].value;

      elem = $("#blocked_bugid");
      var blocked_bugid = elem[0].value;
      elem = $("#dependson_bugid");
      var dependson_bugid = elem[0].value;

    var json_params = '{ "method": "Depinfo.update", "params": { "blocked" : "' + blocked_bugid + '", "dependson" : "' + dependson_bugid + '", "description" : "' + newValue + '"}, "id" : 0 }';
  
    $.post('page.cgi?id=EnhancedTreeView_ajax.html', {
      schema: 'depinfo',
      action: 'update',
      data: json_params
    }, saveResponse, 'text');
  }
