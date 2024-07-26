({

    /**
     * On initialization of this component, set the prechatFields attribute and render prechat fields.
     *
     * @param cmp - The component for this state.
     * @param evt - The Aura event.
     * @param hlp - The helper for this state.
     */
    onInit: function(cmp, evt, hlp) {

        //Prepare Live Chat Link
        var lhnLink = window.location.protocol + "//" + window.location.hostname + "?chatnow=yes";
        cmp.set("v.salesChatLink", lhnLink);

        var prechatFields = cmp.find("prechatAPI").getPrechatFields();

        //Create prechat fields
        var prechatFieldsArray = hlp.getPrechatFieldAttributesArray(prechatFields);
        // Make asynchronous Aura call to create prechat field components.
        $A.createComponents(
            prechatFieldsArray,
            function(components, status, errorMessage) {
                if(status === "SUCCESS") {
                    cmp.set("v.prechatFieldComponents", components);
                }
            }
        );

        //Create Support Fields
        var supportFields = cmp.get('c.createCustomSupportTypePrechatFields');
        supportFields.setParams({cmp: cmp});           
        
        $A.enqueueAction(supportFields);
    },

    // createChatTypeField: function(cmp) {
    //     var type = [
    //         'ui:inputSelect', {
    //             'aura:id' : 'prechatType',
    //             label: $A.get("$Label.c.Prechat_Type"),
    //             disabled: false,
    //             required: "true",
    //             class: 'Type slds-style-select',
    //             options : [
    //                 { value: "Sales", label: "Sales" },
    //                 { value: "Support", label: "Support", selected: true}
    //             ],
    //             change: cmp.getReference("c.handlePress")
    //         }
    //     ];
    //     var fields = [type];

    //     $A.createComponents(
    //         fields,
    //         function(components, status, errorMessage) {
    //             if(status === "SUCCESS") {
    //                 cmp.set("v.chatTypeField", components);
    //                 console.log('Success - Create chat type Fields');
    //             } else if (status === "INCOMPLETE") {
    //                 console.log("No response from server or client is offline.")
    //                 // Show offline error
    //             } else if (status === "ERROR") {
    //                 console.log("Error: ", errorMessage);
    //                 // Show error message
    //             }
    //         }
    //     );
    // },

    createSalesFields: function(cmp) {
        var company = [
            "ui:inputText", {
                'aura:id' : 'prechatCompany',
                label: $A.get("$Label.c.Prechat_Company"),
                disabled: false,
                maxlength: 255,
                class: 'Serial slds-style-inputtext'
            }
        ];
        var fields = [company];

        $A.createComponents(
            fields,
            function(components, status, errorMessage) {
                if(status === "SUCCESS") {
                    cmp.set("v.companyComponent", components);
                } else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                } else if (status === "ERROR") {
                    console.log("Company Error: ", errorMessage);
                    // Show error message
                }
            }
        );
    },

    createCustomSupportTypePrechatFields: function(cmp) {
        var message = [
            "ui:inputTextArea", {
                'aura:id' : 'prechatMessage',
                label: $A.get("$Label.c.Prechat_Message"),
                disabled: false,
                maxlength: 255,
                required: "true",
                class: 'Message slds-style-textarea'
            }
        ];        
        var serial = [
            "ui:inputText", {
                'aura:id' : 'prechatSerial',
                label: $A.get("$Label.c.Prechat_Serial"),
                disabled: false,
                maxlength: 255,
                class: 'Serial slds-style-inputtext'
            }
        ];
        var existingCase = [
            "ui:inputText", {
                'aura:id' : 'prechatExistingCase',
                label: $A.get("$Label.c.Prechat_Existing_Case"),
                disabled: false,
                maxlength: 255,
                class: 'ExistingCase slds-style-inputtext'
            }
        ];
        var fields = [message,serial, existingCase];

        $A.createComponents(
            fields,
            function(components, status, errorMessage) {
                if(status === "SUCCESS") {
                    cmp.set("v.customTypePrechatFieldComponents", components);
                    console.log('Success - Create Custom Type Prechat Fields');
                } else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                } else if (status === "ERROR") {
                    console.log("Error: ", errorMessage);
                    // Show error message
                }
            }
        );
    },

    handlePress : function(cmp, event, helper) {
        // Find the button by the aura:id value
        var src = event.getSource();

        if(src.getLocalId() == "prechatType") {
            var value = src.get("v.value");
            var supportSection = cmp.find("supportSection");
            var salesSection = cmp.find("salesSection");
            var companyField = cmp.find("companyDiv");

            if(value == "Sales") {
                $A.util.addClass(supportSection, 'hideme');
                $A.util.removeClass(salesSection, 'hideme');

                //Show company
                $A.util.removeClass(companyField, 'hideme');

                //Make lastname optional
                cmp.find("prechatFieldLastName").set("v.required", false);

            } else {
                $A.util.addClass(salesSection, 'hideme');
                //Check if fields have been created. If not then create support fields and then unhide the section
                //get support type fields
                var supportFields = cmp.get("v.customTypePrechatFieldComponents");
                if(!supportFields || supportFields.length === 0){
                    var b = cmp.get('c.createCustomSupportTypePrechatFields');
                    b.setParams({cmp: cmp});
                    $A.enqueueAction(b);
                }
                $A.util.removeClass(supportSection, 'hideme');

                //Hide company
                $A.util.addClass(companyField, 'hideme');

                //Make lastname required
                cmp.find("prechatFieldLastName").set("v.required", true);

                
            }
        }

        //console.log("button pressed");
        //console.log(document.cookie);
        //console.log(localStorage);
        //console.log(window.location);
    },

    /**
     * Event which fires when start button is clicked in prechat.
     *
     * @param cmp - The component for this state.
     * @param evt - The Aura event.
     * @param hlp - The helper for this state.
     */
    handleStartButtonClick: function(cmp, evt, hlp) {
        hlp.onStartButtonClick(cmp, evt);
    },
    
    handleConsumerClick: function(cmp, evt, hlp) {
        cmp.set("v.sectionName", "consumer");
    },         
    
    handleBusinessClick: function(cmp, evt, hlp) {
        cmp.set("v.sectionName", "business");
    }     

})