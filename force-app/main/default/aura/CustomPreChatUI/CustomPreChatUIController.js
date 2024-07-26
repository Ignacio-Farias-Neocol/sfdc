({
    /**
    * On initialization of this component, set the prechatFields attribute and render prechat fields.
    *
    * @param cmp - The component for this state.
	* @param evt - The Aura event.
	* @param hlp - The helper for this state.
	*/
	onInit: function(cmp, evt, hlp) {
		// Get prechat fields defined in setup using the prechatAPI component.
		var prechatFields = cmp.find("prechatAPI").getPrechatFields();
		// Get prechat field types and attributes to be rendered.
		var prechatFieldComponentsArray = hlp.getPrechatFieldAttributesArray(cmp.getReference("c.handlePress"), prechatFields);
		var supportPrechatFieldComponentsArray = hlp.getSupportPrechatFieldAttributesArray(prechatFields);
        
        
        
        // Make asynchronous Aura call to create prechat field components.
		$A.createComponents(
			prechatFieldComponentsArray,
			function(components, status, errorMessage) {
				if(status === "SUCCESS") {
					cmp.set("v.prechatFieldComponents", components);

				}
			}
		);
        
        
        $A.createComponents(
			supportPrechatFieldComponentsArray,
			function(components, status, errorMessage) {
				if(status === "SUCCESS") {
					cmp.set("v.supportPrechatFieldComponents", components);

				}
			}
		);
        
        
	},
    
    /**
    * Event which fires when start button is clicked in prechat.
    *
    * @param cmp - The component for this state.
    * @param evt - The Aura event.
    * @param hlp - The helper for this state.
    */
    handleStartButtonClick: function(cmp, evt, hlp) {
    	hlp.onStartButtonClick(cmp);
    },
    
    handlePress: function(cmp, event, helper) {
		var src = event.getSource();
        
        if(src.getLocalId() === "Live_Agent_Type__c") {
	        var value = src.get("v.value");
            
            var cmpWebSerial = cmp.find("Web_Serial__c")
            var cmpWebExistingCase = cmp.find("Web_Existing_Case__c");
            var supportSection = cmp.find("supportSection");
            
            if(value == "Sales") {
                $A.util.addClass(supportSection, 'hideme');
				$A.util.addClass(cmpWebSerial, 'hideme');
                $A.util.addClass(cmpWebExistingCase, 'hideme');
            } else {
                $A.util.removeClass(supportSection, 'hideme');
                $A.util.removeClass(cmpWebSerial, 'hideme');
                $A.util.removeClass(cmpWebExistingCase, 'hideme');
            }

        }
    }
});