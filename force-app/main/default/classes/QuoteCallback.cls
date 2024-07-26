global with sharing class QuoteCallback implements SBQQ.CalculateCallback {
    global void callback(String quoteJSON){
        QuoteModel quoteModel = (QuoteModel)JSON.deserialize(quoteJSON, QuoteModel.Class);  
        quoteModel.record.Quote_Calculated__c = true;
        System.debug('quoteModel...'+quoteModel);
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteModel));       
    }
}