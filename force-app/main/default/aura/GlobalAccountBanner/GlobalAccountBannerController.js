({
    handleRecordChange:	function(component, event, helper) {
	var changeType = event.getParams().changeType;
	
	if (changeType === "LOADED") {
	
		var namedAccount = component.get("v.simpleRecord.Named_Account__c");
		var gloablAccount = component.get("v.simpleRecord.Global_Account__c");
		
		if(gloablAccount == true && namedAccount == true) {
            component.set("v.showAllBanner",true);
			component.set("v.showGlobalBanner",false);
			component.set("v.showNamedBanner",false);
		} else if(namedAccount == true) {
			component.set("v.showNamedBanner",true);
			component.set("v.showGlobalBanner",false);
            component.set("v.showAllBanner",false);
		} else if(gloablAccount == true) {
			component.set("v.showGlobalBanner",true);
			component.set("v.showNamedBanner",false);
            component.set("v.showAllBanner",false);
		} else {
			component.set("v.showGlobalBanner",false);
			component.set("v.showNamedBanner",false);
            component.set("v.showAllBanner",false);
		}
		
	}else if (changeType === "CHANGED") {
	
		var namedAccount = component.get("v.simpleRecord.Named_Account__c");
		var gloablAccount = component.get("v.simpleRecord.Global_Account__c");
		
		if(gloablAccount == true && namedAccount == true) {
            component.set("v.showAllBanner",true);
			component.set("v.showGlobalBanner",false);
			component.set("v.showNamedBanner",false);
		} else if(namedAccount == true) {
			component.set("v.showNamedBanner",true);
			component.set("v.showGlobalBanner",false);
            component.set("v.showAllBanner",false);
		} else if(gloablAccount == true) {
			component.set("v.showGlobalBanner",true);
			component.set("v.showNamedBanner",false);
            component.set("v.showAllBanner",false);
		} else {
			component.set("v.showGlobalBanner",false);
			component.set("v.showNamedBanner",false);
            component.set("v.showAllBanner",false);
		}
	}
	
	$A.get('e.force:refreshView').fire();
}

})