public with sharing class CPQ_ApproveQuote_Controller {
    @AuraEnabled
    public static String approve(String recordId, String notes) {
        String errorMsg;
        try {
            SBQQ__Quote__c quote = new SBQQ__Quote__c(ID = recordId, ApprovalStatus__c = 'Approved');
            update quote;
        } catch (Exception e) {
            errorMsg = e.getMessage();
        }

        return errorMsg;
    }
}