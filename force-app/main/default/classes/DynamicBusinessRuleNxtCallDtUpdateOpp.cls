/**
 * Created by Dilowar Hussain.
 *  @Date 01/03/2023
 *
 *  Description:
 *  
 *  
 *  Added as a part of SFDC-18754
 * 
 */
public with sharing class DynamicBusinessRuleNxtCallDtUpdateOpp implements DynamicBusinessRuleAction{
    /***************************
     * Method Description: 
     * 
     * 
     * @Param: List<Opportunity>
     * @return void
     */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {

        LogModel log = LogModel.startLog('DynamicBusinessRuleNxtCallDtUpdateOpp', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Id renewOppRTID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
        try{
            if(/*triggerContext.contains('Update') ||*/ triggerContext.contains('Insert')){
                //system.debug('Insert opeartion');
                for(SObject rec: records){
                    Opportunity opp01 = (Opportunity) rec;
                    Opportunity opp02 = oldRecordMap == null ? null : (Opportunity)oldRecordMap.get(opp01.Id);
                    if (opp02 == null){opp02 = new Opportunity();}
                    //If CloseDate of the Core & Renewal opportunity is not null or it's changed.
                    if((opp01.Business_Group__c == 'Core' && opp01.CloseDate != NULL && String.valueOf(opp01.recordTypeID).equals(renewOppRTID)) /*|| (opp01.Business_Group__c == 'Core' && opp01.CloseDate != NULL && String.valueOf(opp01.recordTypeID).equals(renewOppRTID) && opp01.CloseDate != opp02.CloseDate)*/){
                        //System.debug('additional conditions satisfied');
                        opp01.Next_Date_Call__c = Date.valueOf(opp01.CloseDate).addDays(-60);
                        //System.debug('Opp Close Date:' +opp01.CloseDate);
                        //System.debug('Next Call Date:' +opp01.Next_Date_Call__c);
                    }
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
}