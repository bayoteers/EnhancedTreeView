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
     Visa Korhonen <visa.korhonen@symbio.com>
  */


  // Id of that field, which is currently in editable state
  var editedFieldid = "";
  
  // Value of field, which was assigned when field became to editable state
  var originalValue = "";
  
  // Value (index) of select-element, which was selected when field became to editable state
  var originalSelectedIndex = "";

function getBugEditableStatusHtml(bug_id, old_content)
{
    var bug_status_field = $("#bug_status_field_html").html();

    // HTML of bug severy contains also JavaScript, that has been commented out
    // This is a problem, because HTML contains script-tag. Parsing HTML from
    // HTML-template stops, when 'script' end tag is encountered. 
    // This makes parsed string to contain 'script' opening tag without ending tag.
    // This in turn makes all HTML disappear after 'script' tag, when string is 
    // concatenated into other text. Solution is to rip off 'script' tag from string.
    var split_index = bug_status_field.indexOf('<script');
    bug_status_field = bug_status_field.substring(0, split_index);

    var template = $("#EditableFieldTmpl").html();
    template = template.replace(/<field_name>/g, 'bug_status');
    template = template.replace(/<bug_id>/g, bug_id);
    template = template.replace('<editable_field>', bug_status_field);
    return template;
}

function getAssignedToUserEditableHtml(bugId, textVal)
{
    var assigned_to_field = '<input size="25" name="inline_assigend_to" value="' + textVal + '" id="inline_assigned_to">';

    var template = $("#EditableFieldTmpl").html();
    template = template.replace(/<field_name>/g, 'assigned_to');
    template = template.replace(/<bug_id>/g, bugId);
    template = template.replace('<editable_field>', assigned_to_field);
    return template;
}

function getBugStatusHtml(bug_id, current_value)
{
    var truncated_value = current_value.substr(0, 4);
    var bug_status_html = 
        '<td id="' + bug_id + '_bug_status_static" title="' + current_value + '" ondblclick="makeeditable(\'' + bug_id + '_bug_status\');">';
    bug_status_html += truncated_value;
    bug_status_html += '</td>';
    return bug_status_html;
}

function getAssignedToHtml(bug_id, current_value)
{
    var assigned_to_html = 
        '<td id="' + bug_id + '_assigned_to_static" title="' + current_value + '" ondblclick="makeeditable(\'' + bug_id + '_assigned_to\');">';
    assigned_to_html += current_value;
    assigned_to_html += '</td>';
    return assigned_to_html;
}

  /**
   * Function checks whether edited field has been changed from original value.
   * If value has changed, field is tried to be saved. Edited field is made hidden
   * static field is made visible. Static field is changed into same value, that is saved, 
   * or original value, if saving is not done.
   *
   * Editable fields of types 'input' and 'select' are handled separately.
   */
  
  function checkIfEditedFieldChanged(mustsave, mustask) {
    var newValue = "";
  
    var bugId = editedFieldid.match(/^\d{1,6}/);
    var fieldName = editedFieldid.substr(bugId[0].length + 1);
  
    if(fieldName == "bug_status")
    {
        checkIfBugStatusFieldChanged(mustsave, mustask, fieldName);
    }
    else if(fieldName == "assigned_to")
    {
        checkIfAssignedToFieldChanged(mustsave, mustask, fieldName);
    }

 
    editedFieldid = "";
    originalValue = "";
  }

  function checkIfAssignedToFieldChanged(mustsave, mustask, fieldName) {
      editableEl = document.getElementById(editedFieldid + "_editable");
      var editEl = editableEl.getElementsByTagName("input")[0];

      if (editEl) {
          // Input element was searched and if it was found, edited field is text-input-type
          newValue = editEl.value;
          // If value is not saved (or it has not changed), original value is restored
          if (newValue != originalValue) {
              if (decidetosave(editedFieldid, fieldName, mustsave, mustask)) {
                  save(editedFieldid, newValue, null /* comment */);
                  makeInputStatic(editedFieldid, newValue);
              } else {
                  makeInputStatic(editedFieldid, originalValue);
              }
          } else {
              makeInputStatic(editedFieldid, originalValue);
          }
     } 
     else {
         // ERROR
     }
  }

  function checkIfBugStatusFieldChanged(mustsave, mustask, fieldName) {
      // Else edited field is selection-element. Selection-element be handled separately.
      editableEl = document.getElementById(editedFieldid + "_editable");
      var selectEl = editableEl.getElementsByTagName("select")[0];
      var selectedIndex = selectEl.selectedIndex;

      if (originalSelectedIndex != selectedIndex) {
        // If value is not saved (or it has not changed), original value is restored
        newValue = selectEl.options[selectedIndex].value;
        var oldValue = selectEl.options[originalSelectedIndex].value;
        if (decidetosave(editedFieldid, fieldName, mustsave, mustask)) {
          var notice = "You have to specify a comment when changing the status of a bug from " + oldValue + " to " + newValue;
          var comment = ""
          while(comment == "") {
              comment = prompt(notice);
          }
          if(comment == null) {
              makeSelectStatic(editedFieldid, originalValue);
          }
          else {
              save(editedFieldid, newValue, comment);
              makeSelectStatic(editedFieldid, selectEl.value);
          }
        } else {
          makeSelectStatic(editedFieldid, originalValue);
        }
      } else {
        makeSelectStatic(editedFieldid, originalValue);
      }
  }

  /**
   * Function makes static field visible and makes editable field hidden,
   * when editable field is type 'select'.
   */
  function makeSelectStatic(fieldid, currentValue) {
    var editableId = fieldid + "_editable";
    var cancelId   = fieldid + "_cancel_icon";
    var saveId     = fieldid + "_save_icon";
    var bugId = fieldid.match(/^\d{1,6}/);
    var newHtml = getBugStatusHtml(bugId, currentValue);
    $('#' + cancelId).remove();
    $('#' + saveId).remove();
    $('#' + editableId).replaceWith(newHtml);
  }
  

  function makeInputStatic(fieldid, currentValue) {
    var bugId = fieldid.match(/^\d{1,6}/);
    var newHtml = getAssignedToHtml(bugId, currentValue);
    var editableId = fieldid + "_editable";
    var cancelId   = fieldid + "_cancel_icon";
    var saveId     = fieldid + "_save_icon";
    $('#' + cancelId).remove();
    $('#' + saveId).remove();
    $('#' + editableId).replaceWith(newHtml);
  }

  /**
   * Function makes static field hidden and editable field visible.
   * Value of edited field is stored so that it can be used when changed value is later saved.
   * While changing the state of one field to editable, id of that field is stored.
   *
   * Static and editable elements are TR-elements. Static element contains static text.
   * Editable TR-element contains element, which is either text-input or select.
   *
   * Editable fields of types 'input' and 'select' are handled separately.
   */
  
  function makeeditable(fieldid) {
    var status = false;
  
    var staticId = fieldid + "_static";
    var staticEl = document.getElementById(staticId);

    if (editedFieldid != "" && editedFieldid != fieldid) {
        status = checkIfEditedFieldChanged(true /* must save */ , true /* must ask first */ );
    }

    editedFieldid = fieldid;
    // HTML-content is changed
    var textVal = staticEl.title;

    var bugId = fieldid.match(/^\d{1,6}/);
    var fieldName = fieldid.substr(bugId[0].length + 1);
    if(fieldName == "bug_status") {
        placeBugStatusSelect(staticEl, bugId, fieldid, textVal);
    }
    else if(fieldName == "assigned_to") {
        placeAssignedToInput(staticEl, bugId, fieldid, textVal);
    }
  
  }

  function placeBugStatusSelect(staticEl, bugId, fieldid, textVal) {
      var editableHtml = getBugEditableStatusHtml(bugId);
      $(staticEl).replaceWith(editableHtml);

      var editableId = fieldid + "_editable";
      var selectEl = document.getElementById(editableId).getElementsByTagName("select")[0];
      var allOptions = selectEl.options;
      var selectedIndex = 0;
      var i = 0;
      for (i = 0; i < allOptions.length; i++) {
        if (allOptions[i].value == textVal) {
          selectedIndex = i;
          break;
        }
      }
      var selectedItem = selectEl.options[selectedIndex];
      originalSelectedIndex = selectedIndex;
      originalValue = selectedItem.value;
      selectEl.value = selectedItem.value; 
  }

  function placeAssignedToInput(staticEl, bugId, fieldid, textVal) {
      var editableHtml = getAssignedToUserEditableHtml(bugId, textVal);
      $(staticEl).replaceWith(editableHtml);
  }

  /**
   * Function solves whether changed value of field will be saved or not.
   */
  
  function decidetosave(fieldid, fieldName, mustsave, mustask) {
    var decission = false;
  
    // If mustsave is false, this function does nothing, but this is really for clarity of code.
    if (mustsave) {
      if (mustask) {
        if (confirm("Do you want to save changes in " + fieldName)) {
          decission = true;
        } else {
          decission = false;
        }
      } else {
        decission = true;
      }
    } else {
      decission = false;
    }
    return decission;
  }

  /**
   * Function saves value.
   */
  
  function save(fieldid, newValue, comment) {
    var bugId = fieldid.match(/^\d{1,6}/);
    var fieldName = fieldid.substr(bugId[0].length + 1);
  
    synchronous_saveBugField(bugId[0], fieldName, newValue, comment);
  }
  
  /**
   * Function is call-back function, that is called after succesfull ajax call returns.
   * Ajax call if succesfull, if server responds without throwing exception. Ordered
   * errors are shown in error message. Function shows status of saving to user.
   */
  
  function saveResponse(response, status, xhr) {
    var retObj = eval("(" + response + ")");

    if (retObj.errors) {
      alert("There are errors: " + retObj.errormsg);
    } else {
      alert("Success");
    }
  }
  
  /**
   * Function saves value of one bug field into database by doing ajax-call.
   */
  
  function saveBugField(bugId, fieldName, newValue) {
    var json_params = '{ "method": "Bug.update", "params": {"ids" : [ {"' + bugId + '": { "' + fieldName + '": "' + newValue + '"} } ] }, "id" : 0 }';
  
    $.post('page.cgi?id=EnhancedTreeView_ajax.html', {
      schema: 'bug',
      action: 'update',
      data: json_params
    }, saveResponse, 'text');
  }
  
  /* Synchronous call for debugging */
  
  function synchronous_saveBugField(bugId, fieldName, newValue, comment) {
    var json_params = "";
    if(comment && comment != "") {
        json_params = '{ "method": "Bug.update", "params": {"ids" : [ {"' + bugId + '": { "' + fieldName + '": "' + newValue + '", "comment": "' + comment + '"} } ] }, "id" : 0 }';
    }
    else {
        json_params = '{ "method": "Bug.update", "params": {"ids" : [ {"' + bugId + '": { "' + fieldName + '": "' + newValue + '"} } ] }, "id" : 0 }';  
    }
    $.ajax({
      async: false,
      url: 'page.cgi?id=EnhancedTreeView_ajax.html',
      data: {
        schema: 'bug',
        action: 'update',
        data: json_params
      },
      success: saveResponse
    });
  }

