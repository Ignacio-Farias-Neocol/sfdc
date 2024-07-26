({
  /**
     * Event which fires the function to start a chat request (by accessing the chat API
     component).
     *
     * @param cmp - The component for this state.
     */
  onStartButtonClick: function (cmp, evt) {
    //prchat fields that are used whether sales or support (all are requried)
    var prechatFieldComponents = [
      cmp.find("prechatFieldFirstName"),
      cmp.find("prechatFieldLastName"),
      cmp.find("prechatFieldEmail")
    ];

    // var prechatFieldComponents = [cmp.find("prechatFieldFirstName"), cmp.find("prechatFieldLastName"), cmp.find("prechatFieldEmail")];
    var prechatFields = cmp.find("prechatAPI").getPrechatFields();
    var apiNamesMap = this.createAPINamesMap(
      cmp.find("prechatAPI").getPrechatFields()
    );

    var fields;
    // Make an array of field objects for the library.
    fields = this.createFieldsArray(apiNamesMap, prechatFieldComponents);

    var inputvalid = this.validateField(cmp.find("prechatMessage")) &&
        cmp.find("prechatAPI").validateFields(fields).valid;

    if (inputvalid) {
      //generate a unique ID for this chat conversation. 
      //We are using this to ensure we create related records only for online chat session
      var snapInUniqueId = this.getSnapInUniqueId();

      var event = new CustomEvent("setCustomField", {
        detail: {
          callback: cmp.find("prechatAPI").startChat.bind(this, fields),
          firstName: cmp.find("prechatFieldFirstName").get("v.value"),
          lastName:
            cmp.find("prechatFieldLastName") &&
            cmp.find("prechatFieldLastName").get("v.value")
              ? cmp.find("prechatFieldLastName").get("v.value")
              : "Unknown",
          email: cmp.find("prechatFieldEmail").get("v.value"),
          message: cmp.find("prechatMessage")
            ? cmp.find("prechatMessage").get("v.value")
            : "Live Chat",
          chatType: "Support",
          serial: cmp.find("prechatSerial")
            ? cmp.find("prechatSerial").get("v.value")
            : "",
          existingCase: cmp.find("prechatExistingCase")
            ? cmp.find("prechatExistingCase").get("v.value")
            : "",
          company: cmp.find("prechatCompany") &&
          cmp.find("prechatCompany").get("v.value")
            ? cmp.find("prechatCompany").get("v.value")
            : "Unknown",
            externalId: snapInUniqueId
        }
      });

      // finally disable the button to prevent double check
      var button = evt.getSource();
      button.set("v.disabled", true);

      // Dispatch the event.
      document.dispatchEvent(event);
    } else {
      console.warn("Prechat fields did not pass validation!");
    }
  },

  //Used to generate a unique Id
  getSnapInUniqueId: function () {
    return (snapInUniqueId =
      this.s4() +
      this.s4() +
      "-" +
      this.s4() +
      "-" +
      this.s4() +
      "-" +
      this.s4() +
      "-" +
      this.s4() +
      this.s4() +
      this.s4());

    var snapInUniqueId = window.localStorage.getItem("snapIn_uniqueId");
    if (snapInUniqueId == null) {
      snapInUniqueId =
        this.s4() +
        this.s4() +
        "-" +
        this.s4() +
        "-" +
        this.s4() +
        "-" +
        this.s4() +
        "-" +
        this.s4() +
        this.s4() +
        this.s4();
      window.localStorage.setItem("snapIn_uniqueId", snapInUniqueId);
    }
    return snapInUniqueId;
  },

  resetSnapInUniqueId: function () {
    window.localStorage.setItem("snapIn_uniqueId", null);
  },

  s4: function () {
    var s4 = Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
    return s4;
  },

  /**
   * Create an array of field objects to start a chat from an array of prechat fields.
   *
   * @param fields - Array of prechat field Objects.
   * @returns An array of field objects.
   */
  createFieldsArray: function (apiNames, fieldCmps) {
    if (fieldCmps.length) {
      return fieldCmps.map(
        function (fieldCmp) {
          if (this.validateField(fieldCmp)) {
            return {
              label: fieldCmp.get("v.label"),
              value: fieldCmp.get("v.value"),
              name: apiNames[fieldCmp.get("v.label")]
            };
          }
        }.bind(this)
      );
    } else {
      return [];
    }
  },
  /**
   * Create map of field label to field API name from the pre-chat fields array.
   *
   * @param fields - Array of prechat field Objects.
   * @returns An array of field objects.
   */
  createAPINamesMap: function (fields) {
    var values = {};
    fields.forEach(function (field) {
      values[field.label] = field.name;
    });
    return values;
  },

  /**
   * Create an array in the format $A.createComponents expects.
   *
   * Example:
   * [["componentType", {attributeName: "attributeValue", ...}]]
   *
   * @param prechatFields - Array of prechat field Objects.
   * @returns Array that can be passed to $A.createComponents
   */
  getPrechatFieldAttributesArray: function (prechatFields) {
    // $A.createComponents first parameter is an array of arrays. Each array contains
    // the type of component being created, and an Object defining the attributes.
    var prechatFieldsInfoArray = [];
    // For each field, prepare the type and attributes to pass to $A.createComponents.
    prechatFields.forEach(function (field) {
        var componentName =
          field.type === "inputSplitName" ? "inputText" : field.type;
        var componentInfoArray = ["ui:" + componentName];
        var className = field.className;
        var attributes = {
          "aura:id": "prechatField" + field.name.replace(/ /g, ""),
          // required: fieldName === "LastName" ? false : field.required,
          required: field.required,
          label: field.label,
          disabled: field.readOnly,
          maxlength: field.maxLength,
          class: className,
          value: field.value
        };
        console.log(attributes);

        // Special handling for options for an input:select (picklist) component.
        if (field.type === "inputSelect" && field.picklistOptions) {
          attributes.options = field.picklistOptions;
        }
        // Append the attributes Object containing the required attributes to render this prechat field.
        componentInfoArray.push(attributes);
        prechatFieldsInfoArray.push(componentInfoArray);
    });
    return prechatFieldsInfoArray;
  },

  /**
   * Validates a single field
   *
   * @param field - The Lighenting field
   * @returns bool
   */
  validateField: function (field) {
    // Clear old errors
    field.set("v.errors", []);
    $A.util.removeClass(field, "required_red");

    if (
      field.get("v.required") &&
      (field.get("v.value") == undefined || field.get("v.value") == "")
    ) {
      field.set("v.errors", [{ message: "Field is required" }]);
      $A.util.addClass(field, "required_red");
      return false;
    }
    //I dont having to do it by class buts its ok for now
    else if (field.get("v.class") == "Email slds-style-inputtext") {
      var email_reg_ex = new RegExp(
        /^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i
      );
      var match = field.get("v.value").match(email_reg_ex);
      if (match == null) {
        field.set("v.errors", [{ message: "Please enter a valid email" }]);
        $A.util.addClass(field, "required_red");
        return false;
      }
    }
    return true;
  }
});