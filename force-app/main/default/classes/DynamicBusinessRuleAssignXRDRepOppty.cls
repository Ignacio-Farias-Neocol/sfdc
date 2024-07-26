/**
 * Created by Dilowar Hussain.
 *  @Date 08/02/2023
 *
 *  Description:
 *  
 *  
 *  Added as a part of SFDC-18146
 */public with sharing class DynamicBusinessRuleAssignXRDRepOppty implements DynamicBusinessRuleAction{
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

        LogModel log = LogModel.startLog('DynamicBusinessRuleAssignXRDRepOppty', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Map<String, String> prQuoteMap = new Map<String, String>();
        List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
        Map<String, String> qtUserMap = new Map<String, String>();
        try{
            if(triggerContext.contains('Update') || triggerContext.contains('Insert')){
                system.debug('Updating opeartion');
                for(SObject rec: records){
                    Opportunity opp01 = (Opportunity) rec;
                    Opportunity opp02 = oldRecordMap == null ? null : (Opportunity)oldRecordMap.get(opp01.Id);
                    if (opp02 == null){opp02 = new Opportunity();}
                    //If Primary quote of the MSP opportunity is not null or it's changed.
                    if((opp01.Business_Group__c == 'MSP' && opp01.SBQQ__PrimaryQuote__c != NULL) || (opp01.Business_Group__c == 'MSP' && opp01.SBQQ__PrimaryQuote__c != NULL && opp01.SBQQ__PrimaryQuote__c != opp02.SBQQ__PrimaryQuote__c)){
                        //opp01.XDR_Rep__c = opp01.SBQQ__PrimaryQuote__c;
                        System.debug('Primary Quote available');
                        prQuoteMap.put(opp01.SBQQ__PrimaryQuote__c, opp01.id);
                    }
                }
                if(!prQuoteMap.isEmpty()){
                    lstQuote = [select id, ownerId from SBQQ__Quote__c where id in :prQuoteMap.keySet()];
                    System.debug('lstQuote is:' +lstQuote);
                    for(SBQQ__Quote__c qt : lstQuote){
                        qtUserMap.put(qt.id, qt.ownerId);
                    }
                }
                System.debug('qtUserMap is:' +qtUserMap);
                for(SObject rec: records){
                    Opportunity opp011 = (Opportunity) rec;
                    opp011.XDR_Rep__c = qtUserMap.get(opp011.SBQQ__PrimaryQuote__c);
                    System.debug('XDR Rep is:' +opp011.XDR_Rep__c);
                }
            }

        }Catch(Exception e){
            System.debug('Exception'+e.getMessage()+ 'occurred at' +e.getStackTraceString());
        }
    }
}