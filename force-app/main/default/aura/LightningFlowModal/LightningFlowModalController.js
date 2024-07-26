({
closeModal:function(component,event,helper){
    component.set('v.ismodalClicked', false);
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('Modalbackdrop');
    $A.util.removeClass(cmpBack,'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
},
openmodal: function(component,event,helper) {
     
    component.set('v.ismodalClicked', true);
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('Modalbackdrop');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
},
     doInit: function(component, event, helper){
       
       //  alert('Before::'+component.get('v.currentUserAccountId')); 
        component.set('v.currentUserAcctId',component.get('v.currentUserAccountId'));
       //  alert('After::'+component.get('v.currentUserAcctId'));
     },
     onRender: function(component, event, helper){
       
         var profileName;
         if(component.get('v.currentUser')!=null)
         {
             profileName= component.get('v.currentUser')['Profile'].Name;
             if (profileName.includes("Admin") || profileName.includes("Administrator") )
         {
              component.set('v.isadminProfile', true);
         }
         }
       // var profileName= component.get('v.currentUser')['Profile'].Name;
        
         
     },
     handleComponentEvent : function(component, event, helper) {
        var valueFromChild = event.getParam("message");
      
        component.set('v.ismodalClicked', false);
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('Modalbackdrop');
    $A.util.removeClass(cmpBack,'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    
    }
    
    })