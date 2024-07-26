/**
* @author Salesforce Services
* @date 03/02/2020
*
* @group Lightning Component Helper
*
* @description Helper class for the Product List View component. Created as part of SFDC-9682
*
*/
public without sharing class ProductListViewHelperExternal {
  
    public final static Integer PAGE_LIMIT = 2;

    //Get Serial details for the logged in user Id
    @AuraEnabled(cacheable=true)
    public static SerialSubDetail getSerialSubDetails(String accountType,
                                                              String fromDateStr,
                                                              String toDateStr, 
                                                              String serialNumber, 
                                                              String endUserString, 
                                                              String partnerString
                                                              ) {
      Map<Id,Account> resellerAccountMap = new Map<Id,Account>();
      if(partnerString != null){
        //List<Account> resellerAccounts = [SELECT Id FROM Account WHERE Name = :partnerString AND Type = 'Partner - Reseller'];
        resellerAccountMap = new Map<Id,Account>([SELECT Id FROM Account WHERE Name = :partnerString AND Type = 'Partner - Reseller']);
        if(resellerAccountMap==null){
          return null;
        }
      }
                                                                                                          
      User userRecord = [SELECT Id, Contact.AccountId,Contact.Account.Type FROM User WHERE Id = :UserInfo.getUserId()];

      // //User Account Id
      String accountId = userRecord.Contact.AccountId;

       // Aditya's change to determine 'Distributor' Account Type
       if(userRecord.Contact != null && userRecord.Contact.Account !=null && userRecord.Contact.Account.Type != null && userRecord.Contact.Account.Type.contains('Distributor')){
        accountType = 'Distributor';
      }
      
      //Map of SKU number and serial Id. 
      //This is needed to get the product name and populate that name in ProductListViewHelper.SerialDetail instance
      Map<String, Set<String>> serialProductNameMap = new Map<String, Set<String>>();
  
      //Map of serial Id and ProductListViewHelper.SerialDetail instance
      Map<String, SerialDetail> serialMap = new Map<String, SerialDetail>();
  
      //Map of serial Id and ProductListViewHelper.SubDetail instance
      Map<String, List<SubDetail>> serialSubMap = new Map<String, List<SubDetail>>();

      //Resolving for SOQL Injection so Sanitizing the AccountType
      String sanitizedAccountType = String.escapeSingleQuotes(accountType);

      // Convert fromDateStr and toDateStr to Date type to resolve the SOQL Injection
      Date fromDate = String.isBlank(fromDateStr) ? null : Date.valueOf(fromDateStr);
      Date toDate = String.isBlank(toDateStr) ? null : Date.valueOf(toDateStr);

      //Variable binding as part of optimizing and resolving the SOQL Injection
      String closedLost = 'Closed Lost';
  
      //Serial Query
      String query = 'SELECT ' + 
                     'End_User_Account__c,' +
                     'End_User_Account__r.Name,' +
                     'Serial__c,' +
                     'Serial__r.Serial_Number__c, Subscription__r.SBQQ__RequiredByProduct__r.Description,Subscription__r.SBQQ__ProductOption__c, Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c, Subscription__r.SBQQ__RequiredById__c, Subscription__r.SBQQ__RequiredByProduct__r.ProductCode,' +
                     'Serial__r.Business_Group__c,' +
                     'Serial__r.Base_Product_SKU__c,' + 
                     'Serial__r.Account__r.Name,' + 
                     'Serial__r.Account__c,' + 
                     'Subscription__r.SBQQ__Contract__c,' +
                     'Subscription__r.SBQQ__Contract__r.ContractNumber,' + 
                     'Subscription__r.SBQQ__Contract__r.Reseller__r.Name,' +
                     'Subscription__r.SBQQ__Contract__r.Reseller__r.Partner_Level__c,' +
                     'Subscription__r.SBQQ__Contract__r.Distributor__r.Name,' +
                     'Subscription__r.SBQQ__Contract__r.EndDate,' +
                     'Subscription__r.SBQQ__ProductName__c,' +
                     'Subscription__r.Product_Description__c,' +
                     'Subscription__r.Current_Quantity__c,' +
                     'Subscription__r.SBQQ__Quantity__c,' +
                     'Subscription__r.SBQQ__SubscriptionStartDate__c,' +
                     'Subscription__r.SBQQ__SubscriptionEndDate__c,' +
                     'Subscription__r.AnnotationReason__c, ' +
                     'Subscription__r.Last_Purchase_Order__c, ' +
                     'Subscription__r.DistributorAccount__r.Name, ' +
                     'Subscription__r.SBQQ__Product__r.Lifecycle_Status__c, ' +
                     'Subscription__r.Reseller_POR__c, ' +
                     'Subscription__r.Auto_Renewal_Flag__c, ' +
                     'Subscription__r.SBQQ__Product__r.ProductCode, ' + 
                     'Subscription__r.SBQQ__Product__r.Description, ' +
                     'Subscription__r.SBQQ__Account__r.Name, ' + 
                     'Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c, ' +	
                     'Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.isClosed, ' +
                     'Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.Bill_To_Account__c, ' +	
                     'Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,' +	
                     'Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.ApprovalStatus__c,' +	
                     'Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.Name' +
                     ' FROM Assigned_Serial__c';
            
      String whereClause = ' WHERE Subscription__c !=null' + 
                           ' AND Subscription__r.SBQQ__RevisedSubscription__c=null' + 
                           ' AND Subscription__r.SBQQ__RenewedDate__c = null' +
                           ' AND Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.StageName != :closedLost';
  
      System.debug('***Account Type: '+ sanitizedAccountType);
      //Based on the account type determine the account field to be used for getting serials
      if(String.isNotBlank(sanitizedAccountType)){
        switch on sanitizedAccountType {
          when 'Customer' {
            whereClause += ' AND Subscription__r.SBQQ__Account__c = :accountId ' + 
                           ' AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:1';
          }
          when 'Reseller' {
            //Reseller is currently using the same field. Keeping it separate to allow for future changes.
            if(!resellerAccountMap.isEmpty()){
              whereClause += ' AND (Subscription__r.SBQQ__Account__c = :accountId OR Subscription__r.SBQQ__Contract__r.Reseller__c IN :resellerAccountMap.keySet()) ' +
                           ' AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:1';
            }else{
              whereClause += ' AND (Subscription__r.SBQQ__Account__c = :accountId OR Subscription__r.SBQQ__Contract__r.Reseller__c = :accountId) ' +
                           ' AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:1';
            }
              
          }
          //Aditya's Change
          when 'Distributor' {
            whereClause += ' AND (Subscription__r.SBQQ__Account__c = :accountId OR Subscription__r.SBQQ__Contract__r.Distributor__c  = :accountId) ' +
                           ' AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:1';
          }
          //By default Subscription Account Id is used
          when else{
            whereClause += ' AND Subscription__r.SBQQ__Account__c = :accountId' + 
                           ' AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:3';
          }
        }
      }

      // Aditya - Added as part of SFDC-17629
      if(String.isNotBlank(serialNumber)) {
        whereClause += ' AND Serial__r.Serial_Number__c = :serialNumber ';  
      }

      // Aditya - Added as part of search endusername fix
      if(String.isNotBlank(endUserString)) {
        whereClause += ' AND Subscription__r.SBQQ__Account__r.Name = :endUserString ';  
      }
      
      System.debug(fromDate);
      if(fromDate != null) {
        whereClause += ' AND Subscription__r.SBQQ__SubscriptionEndDate__c >= :fromDate';
      } 

      if(toDate != null) {
        whereClause += ' AND Subscription__r.SBQQ__SubscriptionEndDate__c <= :toDate';  
      }

      //string never = 'Never';
      //whereClause += ' AND Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c !=: never';

      //Adding Order By Clause
      query +=  whereClause + ' ORDER BY Subscription__r.SBQQ__SubscriptionEndDate__c ASC';
  
      System.debug('QUERY: ' + query);

      //Get query results
      List<Assigned_Serial__c> queryResults = Database.query(query);
  
      System.debug(queryResults);

      Set<String> oppIdWithCase = new Set<String>();
  
      //First loop through queryResults to get open cases for each retrieved renewal opportunity
      //Only for accountType ="Customer" OR "Reseller"
      oppIdWithCase = getRenewalOppWithOpenCase(queryResults);
      

      Set<Id> allSubIds = new Set<Id>();

      //Prepare a map of Product code and Serial Ids with that Product code
      //Prepare a map of Serial Id and ProductListViewHelper.SerialDetail instance
      for(Assigned_Serial__c currentAS: queryResults)
      { 
        /** 1. Loop through each Assigned Serial
         * 2. Check if the map already has this Serial Number
         * 3. If the map has the Serial then compare dates else create an instance of Serial Detail and push it to map
         * 4. Serial Expiration Date Logic
         * 4.1 Check if the Subscription is active. 
         * 4.2 If active compare the date with the expiration date in SerialDetail
         * 4.3 If new sub end date is before the SerialDetail expiration date, then replace it with this new date
         * 4.4 If Contract reseller tied to this sub is different from the partner/disti in SerialDetail then replace it 
         *     with the new one
         * 4.5 If new sub end date is after the SerialDetail expiration date then move to the next Assigned Serial record
         * 4.6 If there are no active subscriptions present then similar comparisons should be done, 
         *     however, this time the latest date will be used as the expiration date
         * 4.7 If multiple subscriptions meet this criteria and they have different contract resellers then show all resellers separated by '|'
         * */ 

        Boolean quoteLineVisibility = String.isNotBlank(currentAS.Subscription__r.SBQQ__ProductOption__c) && 
                                      currentAS.Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c == 'Never' ? false : true;
  
        if(quoteLineVisibility || 
            (!quoteLineVisibility && !allSubIds.contains(currentAS.Subscription__r.SBQQ__RequiredById__c)))
        {
          //Serial Id  
          String serialId = currentAS.Serial__c;
    
          //Base Product SKU (converting to lower case to prevent any issues due to case mismatch in product code)
          String basesku = String.isNotBlank(currentAS.Serial__r.Base_Product_SKU__c)? currentAS.Serial__r.Base_Product_SKU__c.toLowerCase() : '';
    
          //Contract End Date
          Date contractEndDate = currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c;
    
          //Subscription Quantity
          Decimal subQuantity = currentAS.Subscription__r.SBQQ__Quantity__c;
    
          //Subscription current quantity
          Decimal subCurrentQuantity = currentAS.Subscription__r.Current_Quantity__c;
    
          //Partner
          String contractPartner = (accountType == 'Reseller')? currentAS.Subscription__r.SBQQ__Contract__r.Distributor__r.Name: currentAS.Subscription__r.SBQQ__Contract__r.Reseller__r.Name;
    
          /* START: Prepare SerialMap */
          if(serialMap!=null){
            if(serialMap.containsKey(serialId)){
              SerialDetail existingSerialInstance = serialMap.get(serialId);
    
              /*START: CONTRACT END DATE + PARTNER LOGIC*/
              //Check contract end dates
              //Contract end dates are different
              if(existingSerialInstance.contractEndDate!=contractEndDate){
                //Existing Contract date is not in the past
                if(existingSerialInstance.contractEndDate >= Date.today()){
                  //Check if the new contract date is in the past or not. If it is not in past and it is before existing contract end date then use this date
                  if(contractEndDate>=Date.today() && contractEndDate<existingSerialInstance.contractEndDate){
                    //Get the new contract date
                    existingSerialInstance.contractEndDate = contractEndDate;
    
                    //Change the partner to the partner associated with the new date
                    existingSerialInstance.partner = contractPartner;
                  }
                }
                //Existing Contract end date is in the past
                else if(existingSerialInstance.contractEndDate < Date.today()){
                  //If new Contract end date is not in the past or 
                  //it is in the past but after existing contract end date then use new contract end date and related partner
                  if(contractEndDate>=Date.today() || contractEndDate>existingSerialInstance.contractEndDate){
                    //Get the new contract date
                    existingSerialInstance.contractEndDate = contractEndDate;
    
                    //Change the partner to the partner associated with the new date
                    existingSerialInstance.partner = contractPartner;
                  }
                }
              }
              //Contract end Dates are same
              else{
                //Append Reseller name to partner if partners are different and the name is not in the text already
                if(String.isNotBlank(contractPartner)){
                  if(String.isNotBlank(existingSerialInstance.partner)){
                    if(!existingSerialInstance.partner.contains(contractPartner)){
                      existingSerialInstance.partner += '| ' + contractPartner;
                    }
                  }
                  else{
                    existingSerialInstance.partner = contractPartner;
                  }
                } 
              }
              /*END: CONTRACT END DATE + PARTNER LOGIC*/
    
              //Determine Serial status
              existingSerialInstance.status = getEntityStatus(existingSerialInstance.contractEndDate);
    
              //Get status number. This will be used for sorting
              existingSerialInstance.statusNumber = existingSerialInstance.status == 'ACTIVE'? 1: (existingSerialInstance.status == 'RENEW'? 2:3);
    
              //Icon Detail
              existingSerialInstance.iconDetail = prepareIconDetails(existingSerialInstance.status);
            }
            else{
              SerialDetail newSerialInstance = new SerialDetail(basesku,
                                                                contractEndDate,
                                                                serialId,
                                                                contractPartner,
                                                                1,
                                                                currentAS.Serial__r.Serial_Number__c,
                                                                currentAS.Serial__r.Business_Group__c,
                                                                currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,	
                                                                currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.Name,	
                                                                currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c,
                                                                currentAS.End_User_Account__c,
                                                                currentAS.End_User_Account__r.Name
                                                                );
              //Determine if Serial has renewalOppId
              String currentRenewalOpp = currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c;
              if(currentRenewalOpp!=null){
                newSerialInstance.hasRenewalOpp = !currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.isClosed;
                newSerialInstance.hasOpenCase = oppIdWithCase.contains(currentRenewalOpp);
              } else {
                newSerialInstance.hasRenewalOpp = false;
                newSerialInstance.hasOpenCase = false;
              }
              System.debug(newSerialInstance.hasOpenCase);
              System.debug(oppIdWithCase);
              if(currentAS.Subscription__r?.SBQQ__Contract__r?.SBQQ__RenewalOpportunity__r?.Bill_To_Account__c == accountId) {
                newSerialInstance.isBillToAccount = true;
              } else {
                newSerialInstance.isBillToAccount = false;
              }
              System.debug(newSerialInstance.isBillToAccount);
              String quoteId = currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
              String quoteStatus = currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__r.ApprovalStatus__c;
              if(quoteId != null) {
                if(quoteStatus == 'Approved') {
                  newSerialInstance.isQuoteApproved = true;
                } else {
                  newSerialInstance.isQuoteApproved = false;
                }  
              } else {
                newSerialInstance.isQuoteApproved = true;
              }
              //Determine Serial status
              newSerialInstance.status = getEntityStatus(newSerialInstance.contractEndDate);
    
              //Get status number. This will be used for sorting
              newSerialInstance.statusNumber = newSerialInstance.status == 'ACTIVE'? 1: (newSerialInstance.status == 'RENEW'? 2:3);
    
              //Icon Detail
              newSerialInstance.iconDetail = prepareIconDetails(newSerialInstance.status);
              
              serialMap.put(serialId, newSerialInstance);
            }
          }
          /* END: Prepare SerialMap */
    
          /* START: Prepare serialProductNameMap */
          if(serialProductNameMap!=null){                                                       
            if(serialProductNameMap.containsKey(basesku)){
              if(!serialProductNameMap.get(basesku).contains(serialId)){
                serialProductNameMap.get(basesku).add(serialId);
              }
            }
            else{
              serialProductNameMap.put(basesku,
                                        new Set<String> {serialId});
            } 
          }
          /* END: Prepare serialProductNameMap */
    
          /* START: Prepare SerialSubMap */
          if(serialSubMap!=null){
    
            //Determine quantity
            Decimal quantity = subCurrentQuantity!=null ? subCurrentQuantity : subQuantity;

            String prodDescription = quoteLineVisibility?currentAS.Subscription__r.Product_Description__c:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Description;
            
            String prodCode = quoteLineVisibility?currentAS.Subscription__r.SBQQ__Product__r.ProductCode: currentAS.Subscription__r.SBQQ__RequiredByProduct__r.ProductCode;

            //Build the sub object
            SubDetail subInstance = new SubDetail(currentAS.Subscription__c,
                                                  prodDescription,
                                                  quantity,
                                                  currentAS.Subscription__r.SBQQ__SubscriptionStartDate__c,
                                                  currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c,
                                                  currentAS.Subscription__r.SBQQ__Contract__r.ContractNumber,
                                                  currentAS.Subscription__r.AnnotationReason__c,
                                                  currentAS.Subscription__r.SBQQ__Contract__c,
                                                  currentAS.Subscription__r.SBQQ__Account__r.Name,
                                                  currentAS.Subscription__r.Last_Purchase_Order__c,
                                                  currentAS.Subscription__r.SBQQ__Contract__r.Distributor__r.Name,
                                                  currentAS.Subscription__r.Reseller_POR__c,
                                                  currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c,	
                                                  currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c,
                                                  prodCode,
                                                  currentAS.Subscription__r.SBQQ__Product__r.Description,
                                                  currentAS.Subscription__r.Auto_Renewal_Flag__c
                                                  );
            //Determine Sub status
            subInstance.status = getEntityStatus(subInstance.subEndDate);
            subInstance.resellerLevel = currentAS.Subscription__r.SBQQ__Contract__r.Reseller__r.Partner_Level__c;
    
            //Get status number. This will be used for sorting
            subInstance.statusNumber = subInstance.status == 'ACTIVE'? 1: (subInstance.status == 'RENEW'? 2:3);
    
            if(currentAS.Subscription__r.SBQQ__Product__r.Lifecycle_Status__c == 'End of Life') {
              subInstance.lifeCycleStatus = 3;
              subInstance.lifeCycleStatusIcon = new IconDetail('utility:error',
                                                                'error',
                                                                'End of Life',
                                                                'End of Life');
            }
            //Icon Detail
            subInstance.iconDetail = prepareIconDetails(subInstance.status);
    
            SerialDetail serialInstance = serialMap.get(serialId);

            serialInstance.subs.add(subInstance);
          }
          /* END: Prepare SerialSubMap */

          allSubIds.add(quoteLineVisibility?currentAS.Subscription__c:currentAS.Subscription__r.SBQQ__RequiredById__c);
        }
      }
  
      //Get the Product Name using the base product SKU
      for(Product2 currentProduct: [SELECT Name,
                                           Base_SKU__c,
                                           ProductCode 
                                    FROM Product2
                                    WHERE productcode in :serialProductNameMap.keySet()]){
        //Loop through products and assign name in the Serial object instance
        if(serialProductNameMap.containsKey(currentProduct.ProductCode?.toLowerCase())){
          for(String currentSerial : serialProductNameMap.get(currentProduct.ProductCode.toLowerCase())){
            serialMap.get(currentSerial).productName = currentProduct.Name;
          }
        }
      }
      
      System.debug('Serials Size: ' + serialMap.size());
  
      return new SerialSubDetail(serialMap.values(), serialSubMap);
    }  
    
    private static Set<String> getRenewalOppWithOpenCase(List<Assigned_Serial__c> queryResults) {
      Set<String> renewalOppId = new Set<String>();
      for(Assigned_Serial__c currentAS: queryResults)
      {
        if(currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c!=null) {	
          renewalOppId.add(currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c);
        }
      }
      System.debug(renewalOppId);
      Schema.DescribeSObjectResult caseResult = Case.SObjectType.getDescribe();
      Map<String, Schema.RecordTypeInfo> caseIdMap = caseResult.getRecordTypeInfosByName();
      Set<String> oppIdWithCase = new Set<String>();
      //Handling Null or Empty 
      String communityQuoteId = '';
      if(caseIdMap.containsKey('Community Quote')) {
          communityQuoteId = caseIdMap.get('Community Quote').getRecordTypeId();
      }  
      String caseQuery = 'Select ' + 
                          'Id, ' +
                          'Opportunity_for_SE_Cases__c ' +  
                          'FROM Case ' +
                          'WHERE RecordTypeId = :communityQuoteId ' +
                          'AND IsClosed = false ' + 
                          'AND Opportunity_for_SE_Cases__c in :renewalOppId';
  
      for(Case caseRecord: Database.query(caseQuery))
      {
        oppIdWithCase.add(caseRecord.Opportunity_for_SE_Cases__c);
      }
      return oppIdWithCase;
    } 
  
    /* Gets the status value based on the date passed */
    private static String getEntityStatus(Date endDate){
      String status = 'ACTIVE';
      //Determine Serial status
      if(endDate!=null){
        if(endDate < Date.today()){
          status = 'INACTIVE';
        }                                    
        else if(endDate >= Date.today()){
          status = endDate > Date.today().addDays(60) ? 'ACTIVE' : 'RENEW';
        }  
      }
      else{
        status = 'ACTIVE'; //Check with business
      }
      return status;
    }  
  
    /* Get Icon details based on Status */
    private static ProductListViewHelper.IconDetail prepareIconDetails(String status){
      ProductListViewHelper.IconDetail iconDetail;
      if(String.isNotBlank(status)){
        switch on status {
          when 'ACTIVE'{
            iconDetail = new ProductListViewHelper.IconDetail('utility:success',
                                                              'Success',
                                                              'Active',
                                                              'Active');
          }
          when 'INACTIVE' {
            iconDetail = new ProductListViewHelper.IconDetail('utility:error',
                                                              'error',
                                                              'Expired/Returned/Exchaged',
                                                              'Expired/Returned/Exchaged');
          }
          when 'RENEW'{
           iconDetail = new ProductListViewHelper.IconDetail('utility:warning',
                                                             'warning',
                                                             'Upcoming Renewal',
                                                             'Upcoming Renewal');
          }
        }
      }
    
      return iconDetail;
    } 
  
    //Object containing Serials and Subscription details to be sent to LWC
    public class SerialSubDetail{
  
      //list of serials to be shown on the page
      @AuraEnabled
      public List<SerialDetail> serials;
  
      //Subscription for each serial
      @AuraEnabled
      public Map<String, List<SubDetail>> serialSubMap;
  
      public SerialSubDetail(List<SerialDetail> serials, 
                             Map<String, List<SubDetail>> serialSubMap){
        
        this.serials        = serials;
        this.serialSubMap   = serialSubMap;
      }    
    }
  
    //Serial data model
    public class SerialDetail{
      //Do not change the property names of this class.
      //These property names correspond to the attributes shown on Serial Card
  
      @AuraEnabled
      public String baseProductSKU;
  
      @AuraEnabled
      public Date contractEndDate;
      
      @AuraEnabled
      public String id;
   
      @AuraEnabled
      public String partner;
      
      @AuraEnabled
      public String productName;
  
      @AuraEnabled
      public Integer quantity; 
  
      @AuraEnabled
      public String serialNumber;
  
      @AuraEnabled
      public String status; //Can contain 3 values > ACTIVE, INACTIVE, RENEW
  
      @AuraEnabled
      public Integer statusNumber; //1 => Active. 2 => Renew, 3 => Inactive
  
      @AuraEnabled
      public ProductListViewHelper.IconDetail iconDetail;
  
      @AuraEnabled
      public String businessGroup;
  
      @AuraEnabled
      public Boolean hasOpenCase;
  
      @AuraEnabled
      public Boolean hasRenewalOpp;

      @AuraEnabled
      public Boolean isBillToAccount;

      @AuraEnabled
      public Boolean isQuoteApproved;
  
      @AuraEnabled
      public String quoteId;
  
      @AuraEnabled
      public String quoteName;
  
      @AuraEnabled
      public String renewalOppId;
  
      @AuraEnabled
      public String accountId;
  
      @AuraEnabled
      public String accountName;

      @AuraEnabled
      public List<SubDetail> subs;
  
      public SerialDetail(String baseProductSKU, 
                          Date contractEndDate,
                          String id,
                          String partner,                        
                          Integer quantity,
                          String serialNumber,
                          String businessGroup,
                          String quoteId,
                          String quoteName,
                          String renewalOppId,
                          String accountId,
                          String accountName){
        
        this.baseProductSKU   = baseProductSKU;
        this.contractEndDate  = contractEndDate;
        this.id               = id;
        this.partner          = partner;
        this.quantity         = quantity;
        this.serialNumber     = serialNumber;
        this.businessGroup    = businessGroup;
        this.quoteId          = quoteId;
        this.quoteName        = quoteName;
        this.renewalOppId     = renewalOppId;
        this.accountId        = accountId;
        this.accountName      = accountName;
        this.subs = new List<SubDetail>();
      }
    }
  
    //Subscription data model
    public class SubDetail{
      //Do not change the property names of this class.
      //These property names correspond to the attributes shown on Serial Card
  
      @AuraEnabled
      public String id;
  
      @AuraEnabled
      public String productName; 
      
      @AuraEnabled
      public Decimal quantity;
  
      @AuraEnabled
      public Date subStartDate; 
  
      @AuraEnabled
      public Date subEndDate; 
  
      @AuraEnabled
      public String status; //Can contain 3 values > ACTIVE, INACTIVE, RENEW
  
      @AuraEnabled
      public Integer statusNumber; //1 => Active. 2 => Renew, 3 => Inactive 
      
      @AuraEnabled
      public String contractNumber;
        
      @AuraEnabled
      public String AnnotationReason;
      
      @AuraEnabled
      public String contractId;    
  
      @AuraEnabled
      public ProductListViewHelper.IconDetail iconDetail;
  
      @AuraEnabled
      public String endUserName;
  
      @AuraEnabled
      public String lastPurchaseOrderNumber;
  
      @AuraEnabled
      public String distributor;
  
      @AuraEnabled
      public Integer lifeCycleStatus;
  
      @AuraEnabled
      public IconDetail lifeCycleStatusIcon;
  
      @AuraEnabled
      public String reseller;
      
      @AuraEnabled
      public String resellerLevel;

      @AuraEnabled
      public String opportunityId;
  
      @AuraEnabled
      public String quoteId;
  
      @AuraEnabled
      public String SKU;
  
      @AuraEnabled
      public String subscriptionDescription;

      @AuraEnabled
      public Boolean autoRenewal;
  
      public SubDetail(String id,
                       String productName,
                       Decimal quantity,
                       Date subStartDate,                       
                       Date subEndDate, 
                       String contractNumber,
                       String AnnotationReason,
                       String contractId,
                       String endUserName,
                       String lastPurchaseOrderNumber,
                       String distributor,
                       String reseller,
                       String quoteId,
                       String opportunityId,
                       String SKU,
                       String subscriptionDescription,
                       Boolean autoRenewal){
        
        this.id           = id;
        this.productName  = productName;
        this.quantity     = quantity;
        this.subStartDate = subStartDate;
        this.subEndDate   = subEndDate;
        this.contractNumber = contractNumber;
        this.AnnotationReason = AnnotationReason;
        this.contractId   = contractId;
        this.endUserName = endUserName;
        this.lastPurchaseOrderNumber = lastPurchaseOrderNumber;
        this.distributor = distributor;
        this.reseller = reseller;
        this.opportunityId = opportunityId;
        this.quoteId = quoteId;
        this.SKU = SKU;
        this.subscriptionDescription = subscriptionDescription;
        this.autoRenewal = autoRenewal;
      }
    } 
  
    //Icon details data model
    public class IconDetail{
      //Do not change the property names of this class.
      //These property names correspond to the attributes shown on Serial Card
  
      @AuraEnabled
      public String statusIcon;
  
      @AuraEnabled
      public String statusIconVariant; 
      
      @AuraEnabled
      public String statusIconTitle;
  
      @AuraEnabled
      public String statusIconAltText; 
  
      public IconDetail(String statusIcon,
                        String statusIconVariant,
                        String statusIconTitle,
                        String statusIconAltText){
        
        this.statusIcon        = statusIcon;
        this.statusIconVariant = statusIconVariant;
        this.statusIconTitle   = statusIconTitle;
        this.statusIconAltText = statusIconAltText;
      }
    }   
  }