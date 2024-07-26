/**
 * Created by iyeung on 1/22/19.
 * Modified by pshetty on 11/21/2019 for https://bugs.cudaops.com/browse/SFDC-8683 to send deal reg for Hot list
 * Modified by pshetty on 12/09/2019 for https://bugs.cudaops.com/browse/SFDC-8118 to send account info to BOS on Opp Closed Won
 */


public with sharing class PartnerPortalUpdateHelper {

//    private static String baseUrlProduction = 'https://www.barracuda.com/web_api/update_resellerdata_from_sf_trigger/';
//    private static String baseUrlSanbox = 'https://www.barracuda.com/web_api/update_resellerdata_from_sf_trigger_sandbox/';
//    private static String baseUrlProductionCtc = 'https://www.barracuda.com/web_api/update_contact_from_sf_trigger/';
//    private static String baseUrlSanboxCtc = 'https://www.barracuda.com/web_api/update_contact_from_sf_trigger_sandbox/';
//    private static String endUrlProduction = '?uname=webprod&pswd=14273371c52b0b162c5748169c69ad17';
//    private static String endUrlSandbox = '?uname=webprod&pswd=14273371c52b0b162c5748169c69ad17';


    private static final String TRANSACTION_CONTACT    = 'Update_Contact';
    private static final String TRANSACTION_RESELLER   = 'Update_Reseller';
    private static final String TRANSACTION_DEALREG    = 'Deal_Reg';
    private static final String TRANSACTION_DEALREG_HL = 'Deal_Reg_HotList';

    //SFDC-8683 Adding static variable to prevent multiple execution of this class for multiple changes on the same record
    //Currently being used in Opp Deal Reg and Hotlist Deal Reg
    private static Boolean firstRun = true;

    private static final List <String> PORTAL_PARTNER_TYPES = new List <String> {'Distributor', 'Partner - Reseller', 'Partner - Hybrid', 'Partner - Referral'};

    private static Map<String, Web_Integration_Setting__mdt> webSettings = new Map<String, Web_Integration_Setting__mdt> ();
    static {

        for (Web_Integration_Setting__mdt s:   [select Base_URL__c, DeveloperName, Id, Label, Language, MasterLabel,
                NamespacePrefix, Parameter1_Label__c, Parameter1_Value__c, Parameter2_Label__c, Parameter2_Value__c,
                Parameter3_Label__c, Parameter3_Value__c, QualifiedApiName from Web_Integration_Setting__mdt
        where DeveloperName in ( :TRANSACTION_RESELLER, :TRANSACTION_CONTACT, :TRANSACTION_DEALREG, :TRANSACTION_DEALREG_HL)]){
            webSettings.put(s.DeveloperName, s);
        }
    }

    private static String getBaseUrl(String transType){
        return webSettings.get(transType).Base_URL__c;
    }

    private static String getEndUrl(String transType){

        return '?' + webSettings.get(transType).Parameter1_Label__c  + '=' + webSettings.get(transType).Parameter1_Value__c + '&'  + webSettings.get(transType).Parameter2_Label__c  + '=' + webSettings.get(transType).Parameter2_Value__c;

    }

    public static Boolean hasChanged(Contact newContact, Contact oldContact)
    {
        // fields in Cuda gold but not in Apollo : || newContact.Contact_Type__c != oldContact.Contact_Type__c
        return  (newContact != null && oldContact == null ) // if old contact is null, assume changed
                || newContact.LastName != oldContact.LastName
                || newContact.FirstName != oldContact.FirstName
                || newContact.Phone != oldContact.Phone
                || newContact.Email != oldContact.Email
                || newContact.Partner_Portal_Access__c != oldContact.Partner_Portal_Access__c
                || newContact.Contact_Status__c != oldContact.Contact_Status__c
                || newContact.accountid != oldContact.accountid;
    }

    public static Boolean hasChanged(Account newAccount, Account oldAccount)
    {
        return (newAccount != null && oldAccount == null ) // if old account is null, assume changed
                || newAccount.Name != oldAccount.Name
                // || newAccount.Disti_that_VAR_sources_from__c != oldAccount.Disti_that_VAR_sources_from__c
                // || newAccount.Exclusive_Distributor__c != oldAccount.Exclusive_Distributor__c
                // || newAccount.Category__c != oldAccount.Category__c
                || newAccount.Type != oldAccount.Type
                || newAccount.ParentId != oldAccount.ParentId
                || newAccount.OwnerId != oldAccount.OwnerId
                || newAccount.Partner_Number__c != oldAccount.Partner_Number__c // || newAccount.ResellerNumber__c != oldAccount.ResellerNumber__c
                || newAccount.Partner_Level__c != oldAccount.Partner_Level__c  // || newAccount.ResellerType__c != oldAccount.ResellerType__c
                || newAccount.BillingStreet != oldAccount.BillingStreet
                || newAccount.BillingCity != oldAccount.BillingCity
                || newAccount.BillingState != oldAccount.BillingState
                || newAccount.BillingCountry != oldAccount.BillingCountry
                || newAccount.BillingPostalCode != oldAccount.BillingPostalCode
                || newAccount.ShippingStreet != oldAccount.ShippingStreet
                || newAccount.ShippingCity != oldAccount.ShippingCity
                || newAccount.ShippingState != oldAccount.ShippingState
                || newAccount.ShippingCountry != oldAccount.ShippingCountry
                || newAccount.ShippingPostalCode != oldAccount.ShippingPostalCode
                || newAccount.Bill_To_Email__c != oldAccount.Bill_To_Email__c  // || newAccount.ContactEmail__c != oldAccount.ContactEmail__c
                || newAccount.Authorized_Countries__c != oldAccount.Authorized_Countries__c
                || newAccount.Strategic_Partner_Type__c != oldAccount.Strategic_Partner_Type__c;

    }

    /*
    public static Boolean eligibleOvderride(Account newAccount, Account oldAccount)
    {
        return newAccount.Type != null && oldAccount.Type != null && newAccount.Type == 'Customer' && oldAccount.Type == 'Partner - Reseller';
    }
     */


    /**
     * updateContact is only trigger if Account.EligibleForPartnerPortalUpdate__c = true
     *
     * @param contactId
     */
    @future(callout=true)
    public static void updateContact(Id contactId)
    {
        List<Contact> contacts = [select Id, Email, AccountId from Contact where Id=:contactId limit 1];
        if(contacts.size() > 0)
        {
            String postURL = getBaseUrl(TRANSACTION_CONTACT) + contacts[0].Id + getEndUrl(TRANSACTION_CONTACT);
            Http h = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(postURL);
            request.setMethod('GET');
            request.setTimeout(60 * 1000);
            if(true) // if(!Test.isrunningTest())
            {
                try
                {
                    HttpResponse res = h.send(request);
                    System.debug(res.getBody());
                    String debugMessage = res.getBody();
                    String regExp = 'pswd.*$';
                    String replacement = '******';
                    String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement);

                    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), contactId, ConnectApi.FeedElementType.FeedItem, 'Notify Portal on contact ' + contactId + ' changes.' + debugMessageCleaned);
                    System.debug(res.getBody());
                }
                catch(Exception ex)
                {
                    try {
                        String debugMessage = ex.getMessage();
                        String regExp = 'pswd.*$';  // hide any password field
                        String replacement = '******';
                        String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement);

                        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), contactId, ConnectApi.FeedElementType.FeedItem, 'Failed to update Portal on this contact ' + contactId + ' changes.' + debugMessageCleaned);

                        // sendErrorNotification('Failed to send contact[Id=' + contacts[0].Id + ', Email=' + contacts[0].Email + ']\r\nError message is: ' + ex.getMessage());
                    } Catch (Exception ex2){
                        System.debug('PartnerPortalUpdateHelper: Error in posting chatter: ' + ex2);
                    }
                }
            }
        }
    }

    /**
     * only trigger if Account.EligibleForPartnerPortalUpdate__c = true
     *
     * @param accountIds
     */
    @future(callout=true)
    public static void updateAccount(List<Id> accountIds)
    {
        List<Account> accounts = [select Id from Account where Id IN :accountIds];
        //if(accounts.size() > 0)
        for(Account account : accounts)
        {
            String postURL = getBaseUrl(TRANSACTION_RESELLER) + account.Id + getEndUrl(TRANSACTION_RESELLER);
            System.debug('~#~#  URL : ' + postURL);
            Http h = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(postURL);
            request.setMethod('GET');
            request.setTimeout(60 * 1000);
            if (true) // if(!Test.isrunningTest())
            {
                try
                {
                    HttpResponse res = h.send(request);
                    System.debug(res.getBody());
                    String debugMessage = res.getBody();
                    String regExp = 'pswd.*$';
                    String replacement = '******';
                    String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement);

                    ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), account.Id, ConnectApi.FeedElementType.FeedItem, 'Notify Portal on account ' + account.Id + ' changes.' + debugMessageCleaned);
                }
                catch(Exception ex)
                {
                    try {
                        String debugMessage = ex.getMessage();
                        String regExp = 'pswd.*$';
                        String replacement = '******';
                        String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement);
                        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), account.Id, ConnectApi.FeedElementType.FeedItem, 'Failed to update Portal on this account ' + account.Id + ' changes.' + debugMessageCleaned);
                        // sendErrorNotification('Failed to send account[Id=' + accountId + '] to partner portal.\r\nThe error message is ' + ex.getMessage());
                    } Catch (Exception ex2){
                        System.debug('PartnerPortalUpdateHelper: Error in posting chatter: ' + ex2);
                    }
                }
            }
        }
    }


    // @future(callout=true)
    // public static void sendDealReg(Id oppId)
    // {
    //     List<Opportunity> opportunities = [select Id, Name from Opportunity where Id=:oppId limit 1];
    //     if(opportunities.size() > 0)
    //     {
    //         String postURL = getBaseUrl(TRANSACTION_DEALREG) + oppId + getEndUrl(TRANSACTION_DEALREG);
    //         System.debug('~#~#  URL : ' + postURL);
    //         Http h = new Http();
    //         HttpRequest request = new HttpRequest();
    //         request.setEndpoint(postURL);
    //         request.setMethod('GET');
    //         request.setTimeout(60 * 1000);
    //         if (true)  // if(!Test.isrunningTest())
    //         {
    //             try
    //             {
    //                 HttpResponse res = h.send(request);
    //                 System.debug(res.getBody());
    //                 String debugMessage = res.getBody();
    //                 String regExp = 'pswd.*$';
    //                 String replacement = '******';
    //                 String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement); // remove password from the chatter post

    //                 ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), oppId, ConnectApi.FeedElementType.FeedItem, 'Submit Deal registration request for ' + opportunities[0].Name + '\n' + 'Response from CMS: \n' + debugMessageCleaned);
    //             }
    //             catch(Exception ex)
    //             {
    //                 try {
    //                     String debugMessage = ex.getMessage();
    //                     String regExp = 'pswd.*$';
    //                     String replacement = '******';
    //                     String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement); // remove password from the chatter post

    //                     ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), oppId, ConnectApi.FeedElementType.FeedItem, 'Failed to submit deal registration for ' +  opportunities[0].Name + '\n' + 'Errors: \n' +  debugMessageCleaned);
    //                     // sendErrorNotification('Failed to send account[Id=' + accountId + '] to partner portal.\r\nThe error message is ' + ex.getMessage());
    //                 } Catch (Exception ex2){
    //                     System.debug('PartnerPortalUpdateHelper: Error in posting chatter: ' + ex2);
    //                 }
    //             }
    //         }
    //     }
    // }

    /** SFDC-8683 Updated the method to work for both Opportunity and Hotlist
     */
    @future(callout=true)
    public static void sendDealReg(List<Id> recordIds)
    {
        if(recordIds!=null && !recordIds.isEmpty()){
            String objectType = recordIds[0].getSobjectType().getDescribe().getName();
        
            //Prepare the query to get object information
            String queryString  = 'Select Id, Name from ' + objectType + ' where Id in :recordIds';     

            //Set the key to get the URL
            String urlKey;

            if(objectType.endsWithIgnoreCase('Opportunity')){
                urlKey = TRANSACTION_DEALREG;
            }
            else if (objectType.endsWithIgnoreCase('Hot_List__c')) {
                urlKey = TRANSACTION_DEALREG_HL;
            }

        //Get the record information
        List<SObject> objList = Database.query(queryString);

            for(SObject obj: objList)
            {
                String postURL = getBaseUrl(urlKey) + (String)obj.get('Id') + getEndUrl(urlKey);
                System.debug('~#~#  URL : ' + postURL);
                Http h = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(postURL);
                request.setMethod('GET');
                request.setTimeout(60 * 1000);
                try
                {
                    HttpResponse res = h.send(request);
                    System.debug(res.getBody());
                    String debugMessage = res.getBody();
                    String regExp = 'pswd.*$';
                    String replacement = '******';
                    String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement); // remove password from the chatter post

                    if(!Test.isRunningTest()){
                        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), (String)obj.get('Id'), ConnectApi.FeedElementType.FeedItem, 'Submit Deal registration request for ' + (String)obj.get('Name') + '\n' + 'Response from CMS: \n' + debugMessageCleaned);
                    }

                    
                }
                catch(Exception ex)
                {
                    try {
                        String debugMessage = ex.getMessage();
                        String regExp = 'pswd.*$';
                        String replacement = '******';
                        String debugMessageCleaned = debugMessage.replaceAll(regExp, replacement); // remove password from the chatter post

                        if(!Test.isRunningTest()){
                            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), (String)obj.get('Id'), ConnectApi.FeedElementType.FeedItem, 'Failed to submit deal registration for ' +  (String)obj.get('Name') + '\n' + 'Errors: \n' +  debugMessageCleaned);
                        }    
                        // sendErrorNotification('Failed to send account[Id=' + accountId + '] to partner portal.\r\nThe error message is ' + ex.getMessage());
                    } Catch (Exception ex2){
                        System.debug('PartnerPortalUpdateHelper: Error in posting chatter: ' + ex2);
                    }
                }
            }               
        }
    }

    /*
    @testVisible
    private static void sendErrorNotification(String message)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(SystemAdminId);
        email.setSubject('Partner Portal Update');
        email.setPlainTextBody(message);
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
        email.setSenderDisplayName('SFDC');
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email }, false);
    }
    */


    public static void  processRecordChanges(Map<Id,SObject> oldRecordMap, List <SObject> records){

        if (records != null && records.size() > 0){
            String objectName = records[0].Id.getSobjectType().getDescribe().getName();

            System.debug('~#~~~~ PartnerPortalUpdateHelper object:' + objectName);

            if (objectName == 'Account'){
                List<Id> accountIds = new  List<Id>();
                for (SObject s : records){
                    Account acc = (Account) s;
                    Account oldAcc = (Account)  oldRecordMap.get(acc.Id);
                    System.debug('~#~~~~ PartnerPortalUpdateHelper acc:' + acc + ' old acc:' + oldAcc);


                    // 2019-05-15: to do: evaluate if Partner_Level__c need to be filtered
                    if(PartnerPortalUpdateHelper.hasChanged(acc, oldAcc) && acc.EligibleForPartnerPortalUpdate__c  ) // && PORTAL_PARTNER_TYPES.indexOf(acc.Type) >= 0 )
                    {
                        accountIds.add(acc.Id);
                        //PartnerPortalUpdateHelper.updateAccount(acc.Id);
                    }
                }
                if(!accountIds.isEmpty()) {
                    PartnerPortalUpdateHelper.updateAccount(accountIds);
                }
            } else if (objectName == 'Contact'){
                for (SObject s : records){
                    Contact contact = (Contact) s;
                    Contact oldContact = (Contact)  oldRecordMap.get(contact.Id);
                    if(PartnerPortalUpdateHelper.hasChanged(contact, oldContact) && contact.EligibleForPartnerPortalUpdate__c ) // && PORTAL_PARTNER_TYPES.indexOf(contact.Account_Type__c) >= 0  )
                    {
                        PartnerPortalUpdateHelper.updateContact(contact.Id);
                    }
                }
            } else if (objectName == 'Opportunity'){
                List<Id> oppIds = new  List<Id>();
                for (SObject s : records){
                    Opportunity opp = (Opportunity) s;
                    Opportunity oldOpp = (Opportunity)  oldRecordMap.get(opp.Id);
                    //SFDC-9016 Adding logic to ensure that Deal Reg is sent for a specific condition
                    //SFDC-8683 updated the logic based on new criteria mentioned in the ticket
                    /** Oppty Stage IS NOT ('Accepted' or 'Closed Won') AND
                        (Deal Reg Status is changed to "Approved" OR 
                        Deal Reg Tracking number is not blank and Deal Reg Status is changed to "Not Approved" OR
                        Deal Reg Tracking number is not blank and Deal Reg Exp date has changed OR
                        Deal Reg Tracking number is not blank and Deal Reg Type has changed)
                         */
                    if(opp.StageName != 'Accepted' && 
                       opp.StageName != 'Closed Won' && 
                       ((opp.Deal_Reg_Status__c != oldOpp.Deal_Reg_Status__c && 
                         (opp.Deal_Reg_Status__c == 'Approved' || 
                          opp.Deal_Reg_Status__c == 'Not Approved')) || 
                        (String.isNotBlank(opp.Deal_Reg_Tracking_No__c) &&  
                         ((oldOpp.Deal_Reg_Exp_Date__c!=null && 
                           opp.Deal_Reg_Exp_Date__c != null &&
                           opp.Deal_Reg_Exp_Date__c != oldOpp.Deal_Reg_Exp_Date__c) || 
                          (String.isNotBlank(oldOpp.Deal_Reg_Type__c) && 
                           String.isNotBlank(opp.Deal_Reg_Type__c) && 
                           opp.Deal_Reg_Type__c!= oldOpp.Deal_Reg_Type__c)))
                       )
                      ){
                        //Add the Id to be sent to the deal reg call
                        oppIds.add(opp.Id);      
                    }

                    //Send opp Ids to the deal reg call
                    if(oppIds!=null && !oppIds.isEmpty()){
                        if(firstRun){
                            //call this method only for the first run
                            PartnerPortalUpdateHelper.sendDealReg(oppIds);                            
                            firstRun = false;

                        }
                        
                    }
                    
                    // Send partner account on opportunity closed won
                    // SFDC-9016 Adding condition to check that the Stage has changed and the Opportunity is Closed Won.
                    if(opp.StageName!= oldOpp.StageName && 
                       opp.StageName == 'Closed Won'){
                        PartnerPortalUpdateHelper.sendAccountAsync(opp.Id);                        
                    }
                }
            }
            //SFDC-8683 Adding code block for hotlist object
            else if(objectName == 'Hot_List__c'){
                List<Id> hotListIds = new  List<Id>();
                for (SObject s : records){
                    Hot_List__c hl = (Hot_List__c) s;
                    Hot_List__c oldhl = (Hot_List__c)  oldRecordMap.get(hl.Id);
                    /** Update is sent to CMS when one of the following conditions are met
                        Hot list deal registration status changes to Approved
                        Hot list deal registration status changes to Not Approved
                        Hot list deal registration status changes to Pending
                        Hot list deal registration type changes to ‘Design In’
                        Hot list deal registration type changes to ‘Denied’
                        Hot list deal registration Deal Reg Exp Date Changes
                        This is triggered by a business rule that checks if Deal_Reg_Status__c or Deal Reg type or Deal_Reg_Exp_Date__c has changed on Hot_List__c record*/
                        if((hl.Deal_Reg_Status__c != oldhl.Deal_Reg_Status__c && String.isNotBlank(hl.Deal_Reg_Status__c)) || 
                           (hl.Deal_Reg_Type__c != oldhl.Deal_Reg_Type__c && String.isNotBlank(hl.Deal_Reg_Type__c)) ||
                           (hl.Deal_Reg_Exp_Date__c != oldhl.Deal_Reg_Exp_Date__c && hl.Deal_Reg_Exp_Date__c != null)
                          ){
                            //Add the Id to the list of Ids to be sent for deal reg
                            hotListIds.add(hl.Id);
                        }
                }

                if(hotListIds!=null && !hotListIds.isEmpty()){
                    if(firstRun){
                        //call this method only for the first run
                        PartnerPortalUpdateHelper.sendDealReg(hotListIds);
                        firstRun = false;
                    }
                }
            }
        }
    }

    @future(callout=true)
    public static void sendAccountAsync(Id recordId) {

        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('PartnerPortalUpdateHelper', 'sendAccountSync');

        //Create a map of Account Id and BOS response
        Map<Id,String> bosResponses = new Map<Id,String>();

        try{
            //SFDC-8118 Adding Reseller and Distributor account Id
            List<Opportunity> opportunities = [Select Id, 
                                                    Name, 
                                                    Reseller__c, 
                                                    Distributor__c 
                                            From Opportunity 
                                            Where Id=:recordId 
                                            Limit 1];
            if(opportunities!=null && !opportunities.isEmpty()) {
                if(opportunities[0].Reseller__c!=null){
                    String resellerResponse = sendAccount(opportunities[0].Reseller__c);
                    if(String.isNotBlank(resellerResponse)) {
                        bosResponses.put(opportunities[0].Reseller__c, resellerResponse);
                    }
                }
                
                //Check that Reseller and Distributor account are not the same. If different then send it to BOS
                if(opportunities[0].Distributor__c!=null && 
                opportunities[0].Distributor__c!=opportunities[0].Reseller__c){
                    String distiResponse = sendAccount(opportunities[0].Distributor__c);
                    if(String.isNotBlank(distiResponse)) {
                        bosResponses.put(opportunities[0].Distributor__c, distiResponse);
                    }
                }
            }

            if(bosResponses!=null && !bosResponses.isEmpty()){
                AccountInfoController.updateSharedPartnerAccount(bosResponses);
            }
        }
        catch (Exception e){
            log.addExceptionLog(e);
        }
    }

    public static String sendAccount(Id recordId) {

        Account account = AccountInfoController.getAccountInfo(recordId);
        String urlEncodedData = urlEncodedAccountData(account);
        List<Web_Integration_Setting__mdt> ws = AccountInfoController.getBosUrl();
        String endpoint = ws[0].Base_URL__c;
        String user = ws[0].Parameter1_Value__c;
        String pwd = ws[0].Parameter2_Value__c;

        // Specify the required credentials to access the endpoint
        Blob creds = Blob.valueOf(user + ':' + pwd);
        String auth = 'Basic ' + EncodingUtil.base64Encode(creds);

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        //req.setClientCertificateName('BOSIntegrationUserCert');

        System.debug('~~~Authorization: ' + auth);   
        System.debug('~~~urlEncodedData: ' + urlEncodedData);  

        
        // Configure the request
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setTimeout(120000);

        // Add basic authentication to header
        req.setHeader('Accept', '*/*');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', auth);
        
        try {
            // Set the request body 
            req.setBody(urlEncodedData);
            
            // Perform callout and set response
            res = http.send(req); 
            // If the request is successful, return the JSON response
            if ((res.getStatusCode() == 200 || res.getStatusCode() == 201) && res.getBody() != null ) {
                System.debug('~~~Received the following result: ' +res.getBody());
                return res.getBody(); 
            } 
            else {
                System.debug('~~~The status code returned was not expected: ' +
                res.getStatusCode() + ' ' + res.getStatus());
            }
        }
        catch(Exception ex) {
             System.debug('~~~PartnerPortalUpdateHelper: Error in sending record to BOS: ' 
                + ex.getMessage() + ' Stack Trace: ' + ex.getStackTraceString());
        }
        return null;
    }

    public static String urlEncodedAccountData(Account account) {

        List<String> urlDataPairs = new List<String>();
        String urlEncodedDataPairs;

        // Turn the data object into an array of URL-encoded key/value pairs.
        if(String.isNotBlank(account.Name))
            urlDataPairs.add('account_name' + '=' + EncodingUtil.urlEncode(account.Name, 'UTF-8'));
        if(String.isNotBlank(account.Bill_To_Contact__c))
            urlDataPairs.add('bill_contact' + '=' + EncodingUtil.urlEncode(account.Bill_To_Contact__c, 'UTF-8'));
        if(String.isNotBlank(account.Ship_To_Contact__c))
            urlDataPairs.add('ship_contact' + '=' + EncodingUtil.urlEncode(account.Ship_To_Contact__c, 'UTF-8'));
        if(String.isNotBlank(account.ShippingStreet))
            urlDataPairs.add('ship_street' + '=' + EncodingUtil.urlEncode(account.ShippingStreet, 'UTF-8'));
        if(String.isNotBlank(account.ShippingCity))
            urlDataPairs.add('ship_city' + '=' + EncodingUtil.urlEncode(account.ShippingCity, 'UTF-8'));
        if(String.isNotBlank(account.ShippingStateCode))
            urlDataPairs.add('ship_state' + '=' + EncodingUtil.urlEncode(account.ShippingStateCode, 'UTF-8'));
        else if(String.isNotBlank(account.ShippingState))
            urlDataPairs.add('ship_state' + '=' + EncodingUtil.urlEncode(account.ShippingState, 'UTF-8'));
        if(String.isNotBlank(account.ShippingPostalCode))
            urlDataPairs.add('ship_pcode' + '=' + EncodingUtil.urlEncode(account.ShippingPostalCode, 'UTF-8'));
        if(String.isNotBlank(account.ShippingCountryCode))
            urlDataPairs.add('ship_country' + '=' + EncodingUtil.urlEncode(account.ShippingCountryCode, 'UTF-8'));
        if(String.isNotBlank(account.BillingStreet))
            urlDataPairs.add('bill_street' + '=' + EncodingUtil.urlEncode(account.BillingStreet, 'UTF-8'));
        if(String.isNotBlank(account.BillingCity))
            urlDataPairs.add('bill_city' + '=' + EncodingUtil.urlEncode(account.BillingCity, 'UTF-8'));
        if(String.isNotBlank(account.BillingStateCode))
            urlDataPairs.add('bill_state' + '=' + EncodingUtil.urlEncode(account.BillingStateCode, 'UTF-8'));
        else if (String.isNotBlank(account.BillingState))
            urlDataPairs.add('bill_state' + '=' + EncodingUtil.urlEncode(account.BillingState, 'UTF-8'));
        if(String.isNotBlank(account.BillingPostalCode))
            urlDataPairs.add('bill_pcode' + '=' + EncodingUtil.urlEncode(account.BillingPostalCode, 'UTF-8'));
        if(String.isNotBlank(account.BillingCountryCode))
            urlDataPairs.add('bill_country' + '=' + EncodingUtil.urlEncode(account.BillingCountryCode, 'UTF-8'));
        if(String.isNotBlank(account.Bill_To_Email__c))
            urlDataPairs.add('bill_contact_email' + '=' + EncodingUtil.urlEncode(account.Bill_To_Email__c, 'UTF-8'));
        if(String.isNotBlank(account.Ship_To_Email__c))
            urlDataPairs.add('ship_contact_email' + '=' + EncodingUtil.urlEncode(account.Ship_To_Email__c, 'UTF-8'));
        if(String.isNotBlank(account.Id))
            urlDataPairs.add('account_id' + '=' + EncodingUtil.urlEncode(account.Id, 'UTF-8'));
        if(String.isNotBlank(account.Phone))
            urlDataPairs.add('bill_phone' + '=' + EncodingUtil.urlEncode(account.Phone, 'UTF-8'));
        if(String.isNotBlank(account.Type))
            urlDataPairs.add('type' + '=' + EncodingUtil.urlEncode(account.Type, 'UTF-8'));
        if(String.isNotBlank(account.VAT_Number__c))
            urlDataPairs.add('vat_id' + '=' + EncodingUtil.urlEncode(account.VAT_Number__c, 'UTF-8'));
        if(String.isNotBlank(account.Tax_Exempt_Number__c))
            urlDataPairs.add('tax_ex' + '=' + EncodingUtil.urlEncode(account.Tax_Exempt_Number__c, 'UTF-8'));
        if(String.isNotBlank(account.Portal_Account_ID__c))
            urlDataPairs.add('portal_id' + '=' + EncodingUtil.urlEncode(account.Portal_Account_ID__c, 'UTF-8'));
        if(String.isNotBlank(String.valueOf(account.Partner_Number__c)))
            urlDataPairs.add('partner_number' + '=' + EncodingUtil.urlEncode(String.valueOf(account.Partner_Number__c), 'UTF-8'));
        /*if(String.isNotBlank(account.Requestor_Buyer__c))
            urlDataPairs.add('buyer' + '=' + EncodingUtil.urlEncode(account.Requestor_Buyer__c, 'UTF-8'));*/
        /*if(String.isNotBlank(account.Requestor_Buyer_email__c))
            urlDataPairs.add('buyer_email' + '=' + EncodingUtil.urlEncode(account.Requestor_Buyer_email__c, 'UTF-8'));*/
        if(String.isNotBlank(account.Account_Status__c))
            urlDataPairs.add('account_status' + '=' + EncodingUtil.urlEncode(account.Account_Status__c, 'UTF-8'));
        if(String.isNotBlank(account.Payment_Terms__c))
            urlDataPairs.add('payment_terms' + '=' + EncodingUtil.urlEncode(account.Payment_Terms__c, 'UTF-8'));

        urlDataPairs.add('option' + '=' + 'create_or_update_account');
        urlDataPairs.add('is_apollo' + '=' + 1);

        urlEncodedDataPairs = String.join(urlDataPairs,'&').replace('%20', '+');

        return urlEncodedDataPairs;
    }

}