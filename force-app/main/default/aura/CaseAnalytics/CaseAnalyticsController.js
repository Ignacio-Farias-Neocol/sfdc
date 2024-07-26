({
    doInit : function(component, event, helper) {
        console.log('doInit');
        var recId = component.get('v.recordId');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsoleNav) {
            if(isConsoleNav){
                workspaceAPI.getEnclosingTabId().then(function(tabId) {
                    //console.log('getEnclosingTabId: '+tabId);
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        var focusedTabId = response.tabId;
                        if(!focusedTabId){
                            window.setTimeout(
                                $A.getCallback(function() {
                                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                                        component.set('v.focusedTabId', tabId);
                                        if(response.tabId === tabId){
                                            helper.startTrackingForCase(component, event, helper, recId);
                                        }
                                    })
                                }), 3000
                            );
                        }
                        //console.log('focusedTabId: '+focusedTabId);
                        //console.log(response.recordId);
                        //console.log('tabId: '+tabId);
                        component.set('v.focusedTabId', tabId);
                        if(focusedTabId === tabId){
                            helper.startTrackingForCase(component, event, helper, recId);
                        }
                    }).catch(function(error) {
                        //console.log(error);
                    });
                }).catch(function(error) {
                    //console.log(error);
                });
            }else{
                helper.startTrackingForCase(component, event, helper, recId);
            }
        }).catch(function(error) {
            //console.log(error);
        });
        window.addEventListener('beforeunload', (event) => {
            //event.preventDefault();
            helper.stopTrackingForCase(component, event, helper, recId, '');
        });
    },
    onTabClosed : function(component, event, helper) {
        var previousTabId = event.getParam('tabId');
        //console.log('onTabClosed - Closing Tab: '+previousTabId);
        var focusedTabId = component.get('v.focusedTabId');
        //console.log('onTabClosed - focusedTabId: '+focusedTabId);
        if(focusedTabId === previousTabId){
            //console.log('onTabClosed - caseId: '+component.get("v.recordId"));
            helper.stopTrackingForCase(component, event, helper, component.get("v.recordId"), '');
        }
    },
    onTabFocused : function(component, event, helper) {
        //console.log('onTabFocused: '+focusedTabId);
        var previousTabId = event.getParam('previousTabId')
        var focusedTabId = event.getParam('currentTabId');
        component.set('v.focusedTabId', focusedTabId);
        var workspaceAPI = component.find("workspace");
        
        //If Previous Tab recordId was a case, stop tracking
        if(previousTabId){
            workspaceAPI.getTabInfo({
                tabId : previousTabId
            }).then(function(response) {
                helper.stopTrackingForCase(component, event, helper, response.recordId, '');
            }).catch(function(error){
                //console.log(error);
            });
        }
        
        //If Focused tab recordId is a Case then start tracking
        if(focusedTabId && component.get('v.creationStarted') === false){
            workspaceAPI.getEnclosingTabId().then(function(tabId) {
                if(focusedTabId === tabId){
                    component.set('v.creationStarted', true);
                    workspaceAPI.getTabInfo({
                        tabId : focusedTabId
                    }).then(function(response) {
                        helper.startTrackingForCase(component, event, helper, response.recordId);
                    }).catch(function(error) {
                        //console.log(error);
                    });
                }
            }); 
        }
    },
    onRecordUpdate : function(component, event, helper) {
        console.log('onRecordUpdate: ');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsoleNav) {
            if(isConsoleNav){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.getEnclosingTabId().then(function(tabId) {
                        if(focusedTabId === tabId){
                            helper.startTrackingForCase(component,event,helper,response.recordId);
                        }
                    }).catch(function(error) {
                        //console.log(error);
                    });
                }).catch(function(error) {
                    //console.log(error);
                });
            }else{
                helper.startTrackingForCase(component.get("v.recordId"));
            }
        }).catch(function(error) {
            //console.log(error);
        });
    },
    handleHashChange : function(component, event, helper) {
        //console.log('handleHashChange');
        var workspaceAPI = component.find("workspace");
        var recId = component.get('v.recordId');
        workspaceAPI.isConsoleNavigation().then(function(isConsoleNav) {
            if(!isConsoleNav && !window.location.href.includes('lightning/r/Case/')){
                //console.log('handleHashChange: '+recId);
                //Move the logic for var action = component.get('c.initData') in the method trackCaseActivity and make only 1 callout
                helper.stopTrackingForCase(component, event, helper, recId, '');
            }
        }).catch(function(error) {
            //console.log(error);
        });
    }
})