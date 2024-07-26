public with sharing class QuoteEditorFooterHelper {
    
    @AuraEnabled(cacheable = false)
    public static void approveQuote(String quoteId) {
        SBQQ__Quote__c quoteRecord = new SBQQ__Quote__c(Id = quoteId);
        quoteRecord.ApprovalStatus__c = 'Approved';

        try {
            update quoteRecord;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}