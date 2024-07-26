({
    onBrowserTabChange : function(component, event, helper,opr) {
        var recId=component.get('v.recordId'); 
        var action = component.get('c.initData');
        
        if(recId){
            action.setCallback(this, function(response) {
                var state = response.getState();
                
                if(state === 'SUCCESS' ){
                    var jsonData = JSON.parse(response.getReturnValue());
                    component.set("v.isTrack",jsonData.isTrack); 
                    component.set('v.isInitDone', true);
                    if(recId && recId.startsWith('500')){
                        
                        component.set('v.currentCaseId', recId);
                        let trackObj = {};
                        trackObj.caseId = recId;
                        trackObj.opr = 'out';
                        var action2 = component.get('c.trackCaseActivity');
                        action2.setParams({ jsonData : JSON.stringify(trackObj) });
                        action2.setCallback(this, function(response) {
                            var state = response.getState();
                            console.log('OnInit state: '+state);   
                            
                            if(state === 'SUCCESS' ){    
                                var jsonData = JSON.parse(response.getReturnValue());
                                console.log('OnInit MSG : '+jsonData.msg);
                                let caseAnalyticId = jsonData.caseAnalyticId;
                                let caseId = jsonData.caseId;
                                
                                if(caseId != undefined){
                                    var action1 = component.get('c.upadateCaseAnalyticsWithCase');
                                    action1.setParams({ caseId : caseId, caseAnalyticId : caseAnalyticId});
                                    action1.setCallback(this, function(response) {
                                        var state = response.getState();
                                        console.log('OnInit Case Updated state: '+state);                                
                                        if(state === 'SUCCESS' ){    
                                            var jsonData = JSON.parse(response.getReturnValue());
                                            console.log('OnInit Case Updated MSG : '+jsonData.msg);
                                        }
                                        else {
                                            
                                            console.log('ERROR', response);
                                            console.log(response);
                                        }
                                    });
                                    $A.enqueueAction(action1);
                                }                                    
                            }
                            else {
                                
                                console.log('ERROR', response);
                                console.log(response);
                            }
                        });
                        $A.enqueueAction(action2);
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },
    setTrackingOut:function(component,event,helper,resObjs){
        console.log('Case Switch Old:'+resObjs.recordId);
        
        let trackObj = {};
        trackObj.caseId = resObjs.recordId;
        trackObj.opr = 'Out';
        var action = component.get('c.trackCaseActivity');
        action.setParams({ jsonData : JSON.stringify(trackObj) });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('Case Switch Old Previous state: '+state);
            if(state === 'SUCCESS' ){
                var jsonData = JSON.parse(response.getReturnValue());
                console.log('Case Switch Old MSG : '+jsonData.msg);
            }
            else {
                console.log('ERROR' , response);
            }
        });
        $A.enqueueAction(action);
    },
    startTrackingForCase: function(component,event,helper,caseId){
        console.log('startTrackingForCase');
        var action = component.get('c.initData');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS' ){
                var jsonData = JSON.parse(response.getReturnValue());
                console.log(jsonData);
                component.set('v.isTrack',jsonData.isTrack);
                component.set('v.isInitDone', true);
                if(jsonData.isTrack){
                    helper.startTrackingForCaseHelper(component,event,helper,caseId);
                }
            }
        });
        $A.enqueueAction(action);  
    },
    startTrackingForCaseHelper: function(component,event,helper,caseId){
        console.log('startTrackingForCase: '+caseId);
        component.set('v.creationStarted', true);
        var recId = caseId;
        if(recId && recId.startsWith('500')){
            var action = component.get('c.getTrackingStatus');
            action.setParams({ caseId : recId});
            action.setCallback(this, function(response) {
                var state = response.getState();
                component.set('v.creationStarted', false);
                if(state === 'SUCCESS' ){
                    var jsonData = JSON.parse(response.getReturnValue());                        
                    let caseAnalyticId = jsonData.caseAnalyticId;
                    component.set('v.caseAnalyticsId', caseAnalyticId);
                    let caseId = jsonData.caseId;
                    if(caseAnalyticId != undefined && caseAnalyticId != null){
                        var action1 = component.get('c.upadateCaseAnalyticsWithCase');
                        action1.setParams({ caseId : caseId, caseAnalyticId : caseAnalyticId});
                        action1.setCallback(this, function(response) {
                            var state = response.getState();
                            console.log('onRecordUpdate Case Updated state: '+state);                                
                            if(state === 'SUCCESS' ){    
                                var jsonData = JSON.parse(response.getReturnValue());
                                console.log('onRecordUpdate Case Updated MSG : '+jsonData.msg);
                            }
                            else {
                                console.log('ERROR' + response);
                            }
                        });
                        $A.enqueueAction(action1);
                    }
                }
                else {
                    console.log('ERROR' + JSON.stringify(response));
                }
            });
            $A.enqueueAction(action);
        }
    },
    stopTrackingForCase: function(component,event,helper,caseId,caseAnalyticsId){
        console.log('caseAnalyticsId: '+component.get('v.caseAnalyticsId'));
        if(caseId && caseId.startsWith('500') && component.get('v.isTrack')){
            console.log('stopTrackingForCase: '+caseId);
            let trackObj = {};
            trackObj.caseId = caseId;
            trackObj.opr = 'Out';
            var action = component.get('c.trackCaseActivity');
            action.setParams({ jsonData : JSON.stringify(trackObj) });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if(state === 'SUCCESS' ){
                    var jsonData = JSON.parse(response.getReturnValue());
                    console.log('Case Close Old MSG : '+jsonData.msg);
                }else{
                    console.log('ERROR', response);
                }
            });
            $A.enqueueAction(action);
        }
    }
})