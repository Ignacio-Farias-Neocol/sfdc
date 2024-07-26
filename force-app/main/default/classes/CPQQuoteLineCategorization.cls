public class CPQQuoteLineCategorization {
    
    @InvocableMethod(label='Get Quote' description='Run to update Quote lines' category='SBQQ__Quote__c')
    Public Static Void getQuote(List<ID> Ids) {
        try{
            List<SBQQ__QuoteLine__c> Qlirecord =[select id,Quote_Line_Categorization__c,Quote_Type__c,Business_Group__c,SBQQ__Quantity__c,SBQQ__RequiredBy__c,EndUserAccount__c,Upsell_Downsell_Subscription__c,Upsell_Downsell_Subscription__r.Product_Code__c,SBQQ__UpgradedSubscription__r.Product_Code__c,SBQQ__RenewedSubscription__c,SBQQ__UpgradedSubscription__c,SBQQ__Quote__r.SBQQ__Account__c,SBQQ__Product__c,SBQQ__Product__r.SBCF_Product_Segment__c,SBQQ__Product__r.ProductCode,SBQQ__Product__r.Family,SBQQ__RenewedSubscription__r.Product_Code__c, SBQQ__RenewedAsset__c,SBQQ__NetTotal__c,SBQQ__Product__r.Previous_Product__c,SBQQ__Quote__r.SBQQ__Type__c  from SBQQ__QuoteLine__c where SBQQ__Quote__c IN: Ids and Business_Group__c ='Core'];
            List<SBQQ__QuoteLine__c> QliUpdate=new List<SBQQ__QuoteLine__c>();
            Set<Id> accountIds = new Set<Id>();
            Set<ID> RenewaSub=New Set<ID>();
            Set<ID>  QliID=new Set<ID>();
            Set<ID> RenewedAssetqliID=New Set<ID>();
            Set<ID>  EDUQliID=new Set<ID>();
            Set<String> previsoproductcodes =New Set<String>();
            for (SBQQ__QuoteLine__c qli : Qlirecord) {
                accountIds.add(qli.EndUserAccount__c);
                if(qli.SBQQ__RenewedSubscription__c != null){
                    RenewaSub.add(qli.SBQQ__RenewedSubscription__c); 
                }
                if(qli.SBQQ__RenewedAsset__c != null){
                    RenewedAssetqliID.add(qli.ID); 
                }

                
            }
 
            List<Opportunity> wonOpps = [SELECT AccountId ,Business_Group__c FROM Opportunity WHERE IsClosed = true AND StageName = 'Closed Won' AND AccountId IN :accountIds and Business_Group__c ='Core' limit 1];
            Set<Id> accountsWithWonOpportunities = new Set<Id>();
            for (Opportunity result : wonOpps) {
                accountsWithWonOpportunities.add((Id)result.get('AccountId'));
            }
            Date last36MonthsDate = System.today().addMonths(-36);
           //Start SFDC-20944
            Boolean NetNewsubscription=false;
            Date currentDate = Date.today();
            Integer windowDays = 30;
            Date thirtyDaysAgo = currentDate.addDays(-windowDays);
            Date firstSubscriptionDate = null;
            List<SBQQ__Subscription__c> subscriptions = [select id,SBQQ__Product__r.Previous_Product__c,SBQQ__EndDate__c,Business_Group__c,SBQQ__Account__c,SBQQ__Product__r.SBCF_Product_Segment__c,SBQQ__Product__r.Family, SBQQ__Product__r.ProductCode,Product_Code__c,CreatedDate  from SBQQ__Subscription__c where SBQQ__EndDate__c >= :last36MonthsDate AND SBQQ__Account__c IN :accountIds and Business_Group__c ='Core' and SBQQ__QuoteLine__r.Quote_Line_Categorization__c ='Net-New' order by CreatedDate ASC limit 1 ];
            if (!subscriptions.isEmpty()) {
                firstSubscriptionDate = subscriptions[0].CreatedDate.date();
            }
            if(firstSubscriptionDate > thirtyDaysAgo){
                NetNewsubscription=true;
            }
            //End SFDC-20944
            List<SBQQ__Subscription__c> activeSubscriptions = [select id,SBQQ__Product__r.Previous_Product__c,SBQQ__EndDate__c,Business_Group__c,SBQQ__Account__c,SBQQ__Product__r.SBCF_Product_Segment__c,SBQQ__Product__r.Family, SBQQ__Product__r.ProductCode,Product_Code__c  from SBQQ__Subscription__c where SBQQ__EndDate__c >= :last36MonthsDate AND SBQQ__Account__c IN :accountIds and Business_Group__c ='Core'];
            Map<Id,SBQQ__Subscription__c > mapofactiveSubscriptions = new Map<Id,SBQQ__Subscription__c>();
            Map<Id, Set<String>> accountToProductSegments = new Map<Id, Set<String>>();
            Map<Id, Set<String>> accountToProductcode = new Map<Id, Set<String>>();
            Map<Id, Set<String>> accountToProductfamily = new Map<Id, Set<String>>();
            Map<Id, Set<String>> accountToProductPrevios = new Map<Id, Set<String>>();
            Set<String> productCodeInOtherSubs=new Set<string>();
            Set<String> productfamilyInOtherSubs=new Set<string>();
            Set<String> productSegmentsInOtherSubs=new Set<string>();
           Set<Id> accountsWithActiveSubscrptionthirtyDaysAgo = new Set<Id>();
            Set<Id> accountsWithActiveSubscrption = new Set<Id>();
            for (SBQQ__Subscription__c Sub : activeSubscriptions) {
                Id accountId = Sub.SBQQ__Account__c;
                String productSegment = Sub.SBQQ__Product__r.SBCF_Product_Segment__c;
                String Productcode = Sub.SBQQ__Product__r.ProductCode;
                String Productfamily = Sub.SBQQ__Product__r.Family;
                mapofactiveSubscriptions.put(sub.id, Sub);
                accountsWithActiveSubscrption.add(Sub.Id);
                if (!accountToProductSegments.containsKey(accountId) || !accountToProductcode.containsKey(accountId) || !accountToProductfamily.containsKey(accountId)) {
                    accountToProductSegments.put(accountId, new Set<String>());
                    accountToProductcode.put(accountId, new Set<String>());
                    accountToProductfamily.put(accountId, new Set<String>());
                    
                }
                
                accountToProductSegments.get(accountId).add(productSegment);
                accountToProductcode.get(accountId).add(Productcode);
                accountToProductfamily.get(accountId).add(Productfamily);
            }
            //SFDC-20614 Changes start 
            for (SBQQ__QuoteLine__c qli : Qlirecord) {
                
                if(RenewaSub.contains(qli.Upsell_Downsell_Subscription__c)){
                    QliID.add(qli.Id);   
                }
                if(RenewedAssetqliID.contains(qli.SBQQ__RequiredBy__c)){
                    EDUQliID.add(qli.SBQQ__RequiredBy__c);
                }
            }
            //End
            for (SBQQ__QuoteLine__c qli : Qlirecord) {
                Id accountId = qli.EndUserAccount__c;
                String currentProductSegment = qli.SBQQ__Product__r.SBCF_Product_Segment__c;
                String currentProductCode = qli.SBQQ__Product__r.ProductCode;
                String currentProductFamily = qli.SBQQ__Product__r.Family;
                String PreviousProductcode= qli.SBQQ__Product__r.Previous_Product__c;
                
                if(accountToProductcode.containsKey(accountId) && accountToProductfamily.containsKey(accountId) && accountToProductSegments.containsKey(accountId)){
                    // Product Family Upsell condition
                    productSegmentsInOtherSubs = accountToProductSegments.get(accountId);
                    productfamilyInOtherSubs = accountToProductfamily.get(accountId);
                    productCodeInOtherSubs = accountToProductcode.get(accountId);
                }
                if(qli.SBQQ__Product__r.SBCF_Product_Segment__c=='other'){
                    qli.Quote_Line_Categorization__c = 'Parts/Shipping';
                    QliUpdate.add(qli);
                    
                }  
                else if(qli.SBQQ__Product__r.SBCF_Product_Segment__c=='Professional Services'){
                    qli.Quote_Line_Categorization__c = 'Pro Services';
                    QliUpdate.add(qli);
                    
                } 
                else if(qli.SBQQ__NetTotal__c==0){
                    
                    qli.Quote_Line_Categorization__c = '';
                    QliUpdate.add(qli);
                }
                //start SFDC-20944
                    else if(!test.isrunningtest() && accountsWithWonOpportunities.contains(accountId) && NetNewsubscription && qli.SBQQ__Quote__r.SBQQ__Type__c !='Renewal') {
                    qli.Quote_Line_Categorization__c = 'Net-New';
                    QliUpdate.add(qli);
                    
                }
                 else if(!test.isrunningtest() && !accountsWithWonOpportunities.contains(accountId) && accountsWithActiveSubscrption.isEmpty()) {
                    qli.Quote_Line_Categorization__c = 'Net-New';
                    QliUpdate.add(qli);
                    
                }
                //END SFDC-20944
                //Example Quote staging-a1Y5x000007ysxIEAQ
                else if (productCodeInOtherSubs.contains(currentProductCode) && qli.SBQQ__RenewedSubscription__c != null && mapofactiveSubscriptions.get(qli.SBQQ__RenewedSubscription__c).id !=Null && mapofactiveSubscriptions.get(qli.SBQQ__RenewedSubscription__c).Product_Code__c == qli.SBQQ__RenewedSubscription__r.Product_Code__c ) {
                    
                    qli.Quote_Line_Categorization__c = 'Renewal';
                    QliUpdate.add(qli);
                } 
                //Example Quote staging-a1Y5x000007ysxIEAQ
                else if (productCodeInOtherSubs.contains(currentProductCode) && qli.SBQQ__RenewedSubscription__c == null && qli.Upsell_Downsell_Subscription__c!=null && mapofactiveSubscriptions.get(qli.Upsell_Downsell_Subscription__c).id !=Null && mapofactiveSubscriptions.get(qli.Upsell_Downsell_Subscription__c).Product_Code__c == qli.Upsell_Downsell_Subscription__r.Product_Code__c ) {
                    
                    qli.Quote_Line_Categorization__c = 'Renewal';
                    QliUpdate.add(qli);
                }
                  //SFDC-20614 Changes start
                else if (productCodeInOtherSubs.contains(currentProductCode) && qli.SBQQ__UpgradedSubscription__c != null && mapofactiveSubscriptions.get(qli.SBQQ__UpgradedSubscription__c).id !=Null && mapofactiveSubscriptions.get(qli.SBQQ__UpgradedSubscription__c).Product_Code__c == qli.SBQQ__UpgradedSubscription__r.Product_Code__c  && qli.SBQQ__NetTotal__c < 0 && qli.SBQQ__Quantity__c==0) {
                    
                    qli.Quote_Line_Categorization__c = 'Renewal';
                    QliUpdate.add(qli);
                } 
                //Example Quote UAT -a1Y5x00000NZJPXEA5
                //SFDC-20740 added
               else if( !productCodeInOtherSubs.isEmpty() && productCodeInOtherSubs.contains(PreviousProductcode) && qli.Quote_Type__c!='Quote'  && qli.SBQQ__RequiredBy__c!=null  )
                {
                    qli.Quote_Line_Categorization__c='Renewal';
                    QliUpdate.add(qli);
                }
               /* else if( !previsoproductcode1.isEmpty() && previsoproductcode1.contains(PreviousProductcode) && qli.Quote_Type__c=='Renewal'  && qli.SBQQ__RequiredBy__c!=null && QliID.contains(qli.SBQQ__RequiredBy__c) && qli.Upsell_Downsell_Subscription__c==null)
                {
                    qli.Quote_Line_Categorization__c='Renewal';
                    QliUpdate.add(qli);
                }*/
                //SFDC-20740 End.
                 //SFDC-20614 End
                else if((qli.SBQQ__Product__r.ProductCode.contains('EDU-FTE') || qli.SBQQ__Product__r.ProductCode.contains('EDU-STU') || qli.SBQQ__Product__r.ProductCode.contains('EduFTE') || qli.SBQQ__Product__r.ProductCode.contains('EduSTU')) && qli.Quote_Type__c=='Renewal'  && qli.SBQQ__RequiredBy__c!=null && EDUQliID.contains(qli.SBQQ__RequiredBy__c))
                {
                    qli.Quote_Line_Categorization__c='Renewal';
                    QliUpdate.add(qli);
                } 
                //Example Quote staging -a1YWJ0000002r0D2AQ
                else if (!productSegmentsInOtherSubs.contains(currentProductSegment)) {
                    qli.Quote_Line_Categorization__c = 'Cross-Sell';
                    QliUpdate.add(qli);
                }
                //Example Quote staging -a1Y5x000007xqKrEAI
                else if (productSegmentsInOtherSubs.contains(currentProductSegment)) {
                    qli.Quote_Line_Categorization__c = 'Product Family Upsell';
                    QliUpdate.add(qli);
                }
                
            }
            if(!QliUpdate.isEmpty()){
                
                Update QliUpdate;
            }
        }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        } 
        
    }
}