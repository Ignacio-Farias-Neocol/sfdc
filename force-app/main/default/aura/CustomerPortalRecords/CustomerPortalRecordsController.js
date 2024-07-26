({
	initialization: function(component,event,helper) {
		var pageNumber = component.get("v.PageNumber");  
        var pageSize = component.find("pageSize").get("v.value"); 
		helper.fetchRecords(component,event,pageNumber,pageSize);
	},

	filterRecords: function(component,event,helper) {
		var pageNumber = component.get("v.PageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
		helper.fetchRecords(component,event,pageNumber,pageSize);
	},
     
    handleNext: function(component,event,helper) {
        var pageNumber = component.get("v.PageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber++;
        helper.fetchRecords(component,event,pageNumber,pageSize);
    },
     
    handlePrev: function(component,event,helper) {
        var pageNumber = component.get("v.PageNumber");  
        var pageSize = component.find("pageSize").get("v.value");
        pageNumber--;
        helper.fetchRecords(component,event,pageNumber,pageSize);
    },
     
    onSelectChange: function(component,event,helper) {
       //10/06 - Pagination Changes
      //  var pageNumber = component.get("v.PageNumber");
		var page = 1;
        var pageSize = component.find("pageSize").get("v.value");
         //alert(page+'--'+pageSize);
		helper.fetchRecords(component,event,page,pageSize);
      //helper.fetchRecords(component,event,pageNumber,pageSize);
    },
	
	navigateToQuestion: function(component,event,helper) {
		var indx = event.target.getAttribute('data-index');
        console.log('indx:'+indx);
        var questionRecord = component.get("v.portalRecords")[indx];
        console.log('questionRecord:'+JSON.stringify(questionRecord));
        var navEvent = $A.get("e.force:force:navigateToURL");
        if(navEvent){
            navEvent.setParams({
                  "url": questionRecord.portalUrl+"/s/question/"+questionRecord.FeedItemId
            });
            navEvent.fire(); 
        }else {
            window.open(questionRecord.portalUrl+"/s/question/"+questionRecord.FeedItemId,"_blank");
        }
	}
})