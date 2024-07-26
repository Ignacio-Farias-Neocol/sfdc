/**
 * Created by Dilowar Hussain on 21/04/2023.
 *  
 *  Description:
 *  This class contains an invocable method and a future method. These 2 methods are 
 *  reposible for Closing lost opportunities when related orders get cancelled. 
 *  
 *  
 *  Added as a part of SFDC-18906
 */
public class CloseParentOppForCancelledOrders {
    /**
     * Decsription: Gets invoked from the flow, "Flow to Invoke Email alert on Order Cancellation".
     * 
     * @Param : List<String>
     * @return: None
     */
    @InvocableMethod 
    public static void invokeClosingOperation(List<String> opptIDs){
        LogModel log = LogModel.startLog('CloseParentOppForCancelledOrders', 'invokeClosingOperation', LogModel.LOG_CATEGORY_APEX);
        Set<String> oppIds = new Set<String>();
        try{
            oppIds.addAll(opptIDs);
            //system.debug('opptIDs is:' +opptIDs);
            closeParentOppty(oppIds);
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('An exception occurred: ' + e.getMessage());
        }
    }
    /**
     * Decsription: Marks opportunities as closd Lost in async mode.
     * 
     * @Param : Set<String>
     * @return: None
     */
    @future
    public static void closeParentOppty(Set<String> oppIds){
        LogModel log = LogModel.startLog('CloseParentOppForCancelledOrders', 'closeParentOppty', LogModel.LOG_CATEGORY_APEX);
        try{
            List<Opportunity> Listopp = new List<Opportunity>();
            Map<ID, Opportunity> errors = new Map<ID, Opportunity>();
            for(Opportunity opp02 : [select id, stageName, Closed_Lost_Reason__c from Opportunity where id in :oppIds]){
                //system.debug('Valid Opportunity available');
                opp02.stageName = 'Closed Lost';
                opp02.Closed_Lost_Reason__c = 'Order Voided';
				Listopp.add(opp02);
            }
            //system.debug('Listopp is' +Listopp);
            if(!Listopp.isEmpty()){
                Database.SaveResult[] srList = Database.update(Listopp, false);
                for (Integer i = 0; i < srList.size(); i++) {
                    Opportunity opp2 = new Opportunity(ID = Listopp[i].Id);
                    Database.SaveResult sr = srList[i];
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred' +e.getStackTraceString());
        }
    }
}