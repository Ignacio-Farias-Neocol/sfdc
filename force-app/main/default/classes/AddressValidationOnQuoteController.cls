/**
 *  @author Jade Global
 *  @date 2021-12-15
 *  @description  Controller to show message on Skout quote of Sensor products group does not have Shipping address.
 */
public class AddressValidationOnQuoteController {
    @AuraEnabled
    public static String setWarningOnQuote(Id quoteId){
        String message = '';
        Boolean hasAddress = true;
        String groupName = '';
        List<String> productCode = Label.SkoutSensorProducts.split(',');
       
        List<SBQQ__QuoteLineGroup__c> quoteGrps = [Select Id, Name, ShipToAddress__c, (Select Id From SBQQ__LineItems__r Where SBQQ__Product__r.Family = 'Skout' AND 
                                                                                       SBQQ__Product__r.ProductCode IN : productCode AND SBQQ__EffectiveQuantity__c > 0) 
                                                  From SBQQ__QuoteLineGroup__c where ShipToAddress__c = null AND SBQQ__Quote__c =: quoteId AND SBQQ__Quote__r.Skout_Quote__c = true 
                                                  AND (SBQQ__Quote__r.SBQQ__Status__c = 'Draft' OR SBQQ__Quote__r.SBQQ__Status__c = 'Denied' OR SBQQ__Quote__r.SBQQ__Status__c = 'Customer Rejected')];

        for(SBQQ__QuoteLineGroup__c grp : quoteGrps){
            if(grp.SBQQ__LineItems__r != null && grp.SBQQ__LineItems__r.Size() > 0){
                groupName +=grp.Name+', '; 
                hasAddress = false;
             } 
        }
        if(hasAddress == false){
            groupName = groupName.removeEnd(', ');
            message = 'Before approval,Address is mandatory on Quote Line Groups for Sensor Products : '+groupName;
            return message; 
        }else{
            return '';
        } 
    }
}