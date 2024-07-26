({		
	fetchRecords: function(component,event,pageNumber,pageSize) {
		component.set("v.isLoaded",false);
		var selectedTopic = component.get("v.mainTopicFilter");
		var selectedComment = component.get("v.bestCommentFilter");
		var selectedDate = component.get("v.dateFilter");	
         // Rahul 
		var showSubTopics = component.find("chkSubTopics").get("v.checked");
		// Rahul 
		var action = component.get("c.getPortalRecords");
        action.setParams({"topicName":selectedTopic,"commentType":selectedComment,
						  "dateFilter":selectedDate,"network":"Partner Community",
						  "pageNumber": pageNumber,"pageSize": pageSize,"showSubTopics":showSubTopics});
		action.setCallback(this, function(response) {
            component.set("v.isLoaded",true);
			var state = response.getState();
			if(state === "SUCCESS") {
				var resultData = response.getReturnValue();
                component.set("v.portalRecords", resultData.resultList);
                component.set("v.PageNumber", resultData.pageNumber);
                component.set("v.TotalRecords", resultData.totalRecords);
                component.set("v.RecordStart", resultData.recordStart);
                component.set("v.RecordEnd", resultData.recordEnd);
                component.set("v.TotalPages", Math.ceil(resultData.totalRecords / pageSize));
			}else {
				console.log("portal record fetch failed");
			}
		});
		
		$A.enqueueAction(action);
	}

})