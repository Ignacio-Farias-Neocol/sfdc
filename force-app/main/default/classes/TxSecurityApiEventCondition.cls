global class TxSecurityApiEventCondition implements TxnSecurity.EventCondition{

    public static String WORKBENCH_CLIENT = 'Workbench';
    

    public TxSecurityApiEventCondition() {

    }

    public boolean evaluate(Sobject event){
        try{
            system.debug('---event----' + event);
            switch on event{
                when ApiEvent apiEvent{
                    return evaluateCondition(apiEvent);
                }
                when null{
                    return false;
                }
                when else{
                    return false;
                }
            }
        }
        catch(Exception e){
            system.debug('---Exception in Transaction Security ---' + e.getMessage());
        }
        return false;
    }

    private boolean evaluateCondition(ApiEvent apiEvent){

        if(apiEvent.Client.contains(WORKBENCH_CLIENT)){
            return evaluateWorkbenchEvent(apiEvent);
        }
        return false;
    }


    //Workbench Events
    private boolean evaluateWorkbenchEvent(ApiEvent workbenchEvent){
        if(checkWorkbenchQueryPermission(workbenchEvent)){
            return true;
        }
        return false;
    }

    private boolean checkWorkbenchQueryPermission(ApiEvent workbenchEvent){
        string permissionSetName = 'Execute_Workbench_Queries';
        system.debug('---user---' + workbenchEvent.UserId);
        system.debug('----query----' + workbenchEvent.Query);
        String userId = (String)workbenchEvent.UserId;
        if(workbenchEvent.Query != null && workbenchEvent.Query != '' && userId != null && userId != ''){
            system.debug('---executing query----');
            List<PermissionSetAssignment> assignment = [Select Id, AssigneeId, PermissionSetId 
                                                        from PermissionSetAssignment 
                                                        Where AssigneeId =: userId 
                                                        AND PermissionSet.Name =: permissionSetName 
                                                        AND IsActive = true];
            
            system.debug('----perm assign----' + assignment);
            if(assignment == null || assignment.size() == 0){
                return true;
            }
        }
        return false;
    }
}