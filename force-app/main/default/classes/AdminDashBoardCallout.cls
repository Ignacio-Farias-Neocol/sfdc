/**
*  @author Jade Global
*  @date 2021-12-15
*  @description  When Opportunity is closed won and has skout quotie, the opportunity products
send to admin dashboard for provisioning and de-provisioning purpose.
*/
public class AdminDashBoardCallout {

    @InvocableMethod(label ='Admin Dashboard call out')
    public static void CallAdminDashBoardAPI(List<String> opportunityId){
        Set<Id> provisionProducts = new Set<Id>();
        Set<Id> deprovisionProducts = new Set<Id>();
        //Get opportunity product quantity to seperate provisioing and de-provisioning products.
        for(OpportunityLineItem lineItem : [Select Id, Quantity, TotalPrice from OpportunityLineItem WHERE PricebookEntry.Product2.Family = 'Skout' AND OpportunityId =: opportunityId[0]]){
            if(lineItem.TotalPrice < 0 || lineItem.Quantity < 0){
                //If quantity is negative then call method for de-provisioning.
                deprovisionProducts.add(lineItem.Id);
            }else{
                //If quantity is negative then call method for provisioning.
                provisionProducts.add(lineItem.Id);
            }
        }
        if(!provisionProducts.isEmpty()){
            provisioningOpportunity(provisionProducts, opportunityId[0]);
        }
        if(!deprovisionProducts.isEmpty()){
            deprovisioningOpportunity(deprovisionProducts, opportunityId[0]);
        }
    }
    
    //Send product for provisioning where product quantity is prositive.
    public static void provisioningOpportunity(Set<Id> provisionProducts, String opportunityId){
        try {
            String jsonBody = PrepareInputJson(provisionProducts, opportunityId); 
            if(!String.isBlank(jsonBody)){
                //If json body is not blank then excute ququeable apex to make callout.
                system.enqueueJob(new AdminDashboardQueueable(jsonBody, 'POST', opportunityId));
            }
        }
        catch(Exception e) {
            System.debug('Callout error: '+ e); 
        }
    }
    
    //Send product for deprovisioning where product quantity is negative.
    public static void deprovisioningOpportunity(Set<Id> deprovisionProducts, String opportunityId){
        try {
            String jsonBody = PrepareInputJson(deprovisionProducts, opportunityId); 
            if(!String.isBlank(jsonBody)){
                //If json body is not blank then excute ququeable apex to make callout.
                system.enqueueJob(new AdminDashboardQueueable(jsonBody, 'DELETE', opportunityId));
            }
        }
        catch(Exception e) {
            System.debug('Callout error: '+ e); 
        }
    }
    
    //Create json request body.
    public static string PrepareInputJson(Set<Id> Opptyproducts, string opportunityId){
        String jsonResponseBody = '';
        Map<String, List<OpportunityLineItem>> lineItemMap = new Map<String, List<OpportunityLineItem>>();
        
        Opportunity oppty = [Select Id, Service_Contact__r.LastName, Service_Contact__r.MobilePhone, Service_Contact__r.Email, 
                             Primary_contact__r.LastName, Primary_contact__r.MobilePhone, Primary_contact__r.Email, 
                             SBQQ__PrimaryQuote__c, AccountId, Account.Name, Account.Terr_Theater__c, Owner.Name, 
                             Owner.MobilePhone, Owner.Email  from Opportunity where Id = :opportunityId];
        
        
        for(OpportunityLineItem lineItem : [Select Name, Quantity, ProductCode, SBQQ__QuoteLine__r.Reseller_Memo_Sonian_Only__c, 
                                            SBQQ__QuoteLine__r.Ship_To_Address__r.State_Name__c, SBQQ__QuoteLine__r.Ship_To_Address__r.Street__c,
                                            SBQQ__QuoteLine__r.Ship_To_Address__r.Zip_Postal_Code__c from OpportunityLineItem where  PricebookEntry.Product2.Family = 'Skout' AND Id In : Opptyproducts]){
                                                if(lineItem.SBQQ__QuoteLine__r.Reseller_Memo_Sonian_Only__c == null || String.isBlank(lineItem.SBQQ__QuoteLine__r.Reseller_Memo_Sonian_Only__c)){
                                                    continue;
                                                }
                                                if(lineItemMap.containsKey(lineItem.SBQQ__QuoteLine__r.Reseller_Memo_Sonian_Only__c)){
                                                    lineItemMap.get(lineItem.SBQQ__QuoteLine__r.Reseller_Memo_Sonian_Only__c).add(lineItem);
                                                }else{
                                                    lineItemMap.put(lineItem.SBQQ__QuoteLine__r.Reseller_Memo_Sonian_Only__c, new List<OpportunityLineItem>{lineItem});
                                                }
                                            }
        
        AdminDashBoardWrapperClass wrapperObj = new AdminDashBoardWrapperClass();
        for(String endUserMsp : lineItemMap.keySet()){
            AdminDashBoardWrapperClass.Deployments deployment = new AdminDashBoardWrapperClass.Deployments();
            
            AdminDashBoardWrapperClass.Contacts technicalContacts = new AdminDashBoardWrapperClass.Contacts();
            technicalContacts.name =oppty.Service_Contact__r.Lastname;
            technicalContacts.mobile = oppty.Service_Contact__r.Mobilephone;
            technicalContacts.email = oppty.Service_Contact__r.Email;
            
            AdminDashBoardWrapperClass.Contacts mainContacts = new AdminDashBoardWrapperClass.Contacts();
            mainContacts.name = oppty.Primary_contact__r.Lastname;
            mainContacts.mobile = oppty.Primary_contact__r.Mobilephone;
            mainContacts.email = oppty.Primary_contact__r.Email;  
            
            AdminDashBoardWrapperClass.Products product;
            AdminDashBoardWrapperClass.Sensors sensor;
            for(OpportunityLineItem oppLineItem : lineItemMap.get(endUserMsp)) {
                product = new AdminDashBoardWrapperClass.Products(); 
                product.code = oppLineItem.ProductCode;
                product.name = oppLineItem.Name;
                if(oppLineItem.Quantity < 0){
                    product.quantity = Integer.ValueOf(oppLineItem.Quantity)*-1;  
                }else{
                    product.quantity = Integer.ValueOf(oppLineItem.Quantity);  
                }
                deployment.products.add(product);
                
                if(oppLineItem.Name.containsIgnoreCase('Sensor')){
                    sensor = new AdminDashBoardWrapperClass.Sensors();
                    sensor.name = oppLineItem.Name;
                    sensor.installSite = oppLineItem.SBQQ__QuoteLine__r.Ship_To_Address__r.Street__c + ' ' + oppLineItem.SBQQ__QuoteLine__r.Ship_To_Address__r.State_Name__c + ' ' + oppLineItem.SBQQ__QuoteLine__r.Ship_To_Address__r.Zip_Postal_Code__c;
                    deployment.sensors.add(sensor);  
                }
            }
            AdminDashBoardWrapperClass.OpportunityOwner oppOwner = new AdminDashBoardWrapperClass.OpportunityOwner();
            oppOwner.email = oppty.owner.Email;
            oppOwner.mobile = oppty.owner.Mobilephone;
            oppOwner.name = oppty.owner.Name;
            deployment.opportunityOwner = oppOwner;
            
            deployment.mspName =oppty.Account.Name;
            deployment.mspAccountID = oppty.AccountId;
            deployment.deploymentName = endUserMsp;
            if(!String.isBlank(oppty.Account.Terr_Theater__c)){
                deployment.theater = oppty.Account.Terr_Theater__c; 
            }else{
                deployment.theater = '';
            }
            deployment.contact.put('main', mainContacts);
            deployment.contact.put('technical', technicalContacts);
            wrapperObj.deployments.add(deployment);
        }
        if(wrapperObj.deployments.size() > 0){
            jsonResponseBody = jsonResponseBody + JSON.serialize(wrapperObj);  
        }
        system.debug('jsonRequestBody = ' +  jsonResponseBody);
        return jsonResponseBody.trim();
    }
    
}