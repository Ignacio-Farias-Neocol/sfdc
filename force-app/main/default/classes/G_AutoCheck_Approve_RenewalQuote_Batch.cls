/**
 * Created by Dilowar Hussain on 08/06/2011.
 *
 *  @Date 2022/06/08
 *  @group Batchable
 *
 *  Description:
 *  This batch class will pick all quotes where CreatedDate > today-120 days and of Renewal type.
 *  If the flag, Available_on_Portal__c for any of these quotes is FALSE, it will mark them as TRUE.
 *  Also, it will set below fields to mark auto approval of the quotes.
 *  SBQQ_Status_c, ApprovalStatus__c.
 *
 *  
 *  Added as a part of SFDC-16741 and SFDC-17358
 */
global with sharing  class G_AutoCheck_Approve_RenewalQuote_Batch implements Database.Batchable<SObject>, Database.Stateful {
    
    public String type = 'Renewal';
    public String approved = 'Approved';
    global Database.QueryLocator start(Database.BatchableContext BC) {  
        String query = 'SELECT Id, Contract_ID__c FROM Auto_Approve_Contract__c WHERE Quote_Approval_Status__c = \'Pending\'';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Auto_Approve_Contract__c> autoApproveRecords){
        try{

            Map<String, Auto_Approve_Contract__c> aacMap = new Map<String, Auto_Approve_Contract__c>();

            for(Auto_Approve_Contract__c autoApproveRecord : autoApproveRecords) {
                aacMap.put(autoApproveRecord.Contract_ID__c, autoApproveRecord);
            }

            List<SBQQ__Quote__c> QuoteList = [SELECT Id, 
                                                     Available_on_Portal__c,
                                                     SBQQ__Status__c, 
                                                     ApprovalStatus__c, 
                                                     SBQQ__Type__c, 
                                                     Created_Date__c, 
                                                     CreatedDate,
                                                     Business_Group__c,
                                                     SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,
                                                     AR_Recalc__c
                                              FROM SBQQ__Quote__c 
                                              WHERE SBQQ__Type__c = :type AND SBQQ__Primary__c= true 
                                                AND (Available_on_Portal__c = false OR SBQQ__Status__c != :approved OR ApprovalStatus__c != :approved) 
                                                AND SBQQ__Opportunity2__r.SBQQ__RenewedContract__c IN :aacMap.keySet()];
            
            Map<String, Auto_Approve_Contract__c> quoteIdToAACMap = new Map<String, Auto_Approve_Contract__c>();
            Map<ID, SBQQ__Quote__c> errors = new Map<ID, SBQQ__Quote__c>();
            List<SBQQ__Quote__c> lstQuote = new List<SBQQ__Quote__c>();
            List<Auto_Approve_Contract__c> aacsToUpdate = new List<Auto_Approve_Contract__c>();
            for(SBQQ__Quote__c qt : QuoteList){
                Auto_Approve_Contract__c aac = aacMap.get(qt.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
                quoteIdToAACMap.put(qt.Id, aac);
                aacMap.remove(qt.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c);
            //SFDC-20062: Don't approve quote if quote is modified
            if(qt.Business_Group__c=='Core' && qt.SBQQ__Status__c=='In Review' && qt.ApprovalStatus__c=='Pending'){
                    if(aac != null) {
                        aac.Quote_Approval_Status__c = 'Success';
                        aacsToUpdate.add(aac);
                    }
                }
                else{
                    qt.Available_on_Portal__c = true;
                    qt.SBQQ__Status__c = 'Approved';
                    qt.ApprovalStatus__c = 'Approved';
                    qt.AR_Recalc__c=true;
                    lstQuote.add(qt);
                }
                
                
            }
            System.Debug('***  lstQuote ' + lstQuote.size());
            if(lstQuote.size()>0){
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;
            Database.SaveResult[] srList = Database.update(lstQuote, false);
            
            for (Integer i = 0; i < srList.size(); i++) {
                SBQQ__Quote__c q = new SBQQ__Quote__c(ID = lstQuote[i].Id);

                Database.SaveResult sr = srList[i];
                if (!sr.isSuccess()) {
                    String errorMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMsg = errorMsg + err.getMessage() + '\n';
                    }

                    //System.Debug('*** error contract ' + q.Id + ', errorMsg ' + errorMsg);
                    q.setOptions(dml);
                    //q.Contract_Error_Check__c = 'RenewalQuoteBatchJob Error: ' + errorMsg;
                    //q.Has_Contract_Error__c = TRUE;
                    q.Available_on_Portal__c=false;
                    errors.put(q.Id, q);

                    Auto_Approve_Contract__c aac = quoteIdToAACMap.get(q.Id);

                    if(aac != null) {
                        aac.Quote_Approval_Status__c = 'Failed';
                        aac.Error_Message__c = errorMsg;
                    }

                    aacsToUpdate.add(aac);
                } else {
                    System.Debug('*** success contract ' + q.Id);

                    Auto_Approve_Contract__c aac = quoteIdToAACMap.get(q.Id);

                    if(aac != null) {
                        aac.Quote_Approval_Status__c = 'Success';
                    }

                    aacsToUpdate.add(aac);
                }
            }
            }
            // Go through any AAC records that didn't have quotes and set them to Failed
            for(Auto_Approve_Contract__c aac : aacMap.values()) {
                aac.Quote_Approval_Status__c = 'Failed';
                aac.Error_Message__c = 'Quote not found';

                aacsToUpdate.add(aac);
            }

            if(!aacsToUpdate.isEmpty()) {
            System.Debug('***  aacsToUpdate ' + aacsToUpdate.size());
                update aacsToUpdate;
            }

            if (errors.size() > 0)
                Database.update(errors.values(), false);

        } Catch(Exception e){
            System.debug('Exception occurred at:' +e.getStackTraceString());
            System.debug('Exception occurred at:' +e);
        }
    }

    global void finish(Database.BatchableContext BC){}

    
}