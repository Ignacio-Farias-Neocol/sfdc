public with sharing class OppBasedQuoteUpdates {

    @future
    public static void executeLog(String jsonString){

        // Log Instance
        LogModel log = LogModel.startLog('OppBasedQuoteUpdates', 'Update Quotes based on Opp values');

        // Update quotes
        List<SBQQ__Quote__c> quoteList = (List<SBQQ__Quote__c>)Json.deserialize(jsonString, List<SBQQ__Quote__c>.class);
        
        if (quoteList != null && !quoteList.isEmpty()) {

            // Updating quotes
            log.addLog('Quote List size' + quoteList.size());

            Database.SaveResult[] srList = Database.update(quoteList, false);

            for (Database.SaveResult sr : srList) {

                if (sr.isSuccess()) {

                    String errorMessage = 'Error';

                    for (Database.Error err : sr.getErrors()) {
                        errorMessage += err.getMessage();
                    }

                    log.addLog(errorMessage);
                }
            }
        }
    }
}