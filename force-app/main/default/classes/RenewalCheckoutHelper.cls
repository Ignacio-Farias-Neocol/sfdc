public without sharing class RenewalCheckoutHelper {

  @AuraEnabled(cacheable=false)
  public static Boolean renewalPreCheck(String quoteId) {
    Boolean quoteIsReady = true;
    SBQQ__Quote__c quoteRecord = [SELECT 
                                    Shipping_Address__c,
                                    Billing_Address__c,
                                    SBQQ__Status__c,
                                    ApprovalStatus__c,
                                    SBQQ__Opportunity2__c
                                  FROM SBQQ__Quote__c
                                  WHERE Id = :quoteId];
    //Check if quote is approved
    if((quoteRecord.SBQQ__Status__c != 'Approved' && quoteRecord.SBQQ__Status__c != 'Presented' && quoteRecord.SBQQ__Status__c != 'Customer Accepted') || quoteRecord.ApprovalStatus__c != 'Approved') {
      quoteIsReady = false;
    }

    //Check if address fields are populated
    if(quoteRecord.Shipping_Address__c == null || quoteRecord.Billing_Address__c == null) {
      Contract con = [SELECT
                        Id,
                        Shipping_Address__c,
                        Billing_Address__c
                        FROM Contract 
                      WHERE SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c = :quoteId LIMIT 1];
      
      Opportunity opp = new Opportunity(Id = quoteRecord.SBQQ__Opportunity2__c);
      opp.Shipping_Address__c = quoteRecord.Shipping_Address__c == null ? con.Shipping_Address__c : quoteRecord.Shipping_Address__c;
      opp.Billing_Address__c = quoteRecord.Billing_Address__c == null ? con.Billing_Address__c : quoteRecord.Billing_Address__c;

      try {
        update opp;
      } catch(Exception e) {
        quoteIsReady = false;
      }
    }

    return quoteIsReady;
  }

  @AuraEnabled(cacheable=true)
  public static SerialQuoteLineDetail getQuoteLineDetails(String quoteId) {
    
    SerialQuoteLineDetail data = new SerialQuoteLineDetail();
    List<SerialDetail> serialDetails = new List<SerialDetail>();
    Map<String, List<QuoteLineDetail>> serialQuoteLineMap = new Map<String, List<QuoteLineDetail>>();

    //extract QL ids Map<id, SBQQ__QuoteLine_c = Database.query()
    /**
     * SFDC-17202: Added an extra condition as Is_Optional__c = FALSE: 
     * **********  Added new fields Product_Description__c, Extended_List_Unit_Price__c to the query.
     * ********** START
     * */
    Map<Id, SBQQ__QuoteLine__c> quoteLineIdMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT 
                                                 Id,
                                                 SBQQ__Quote__r.SBQQ__Opportunity2__c,
                                                 SBQQ__Quote__r.SBQQ__Opportunity2__r.Bill_To_Account__c,
                                                 SBQQ__Quote__r.SBQQ__Opportunity2__r.Bill_To_Account__r.Name,
                                                 SBQQ__Quote__r.SBQQ__Opportunity2__r.AccountId,
                                                 SBQQ__Quote__r.SBQQ__Opportunity2__r.Account.Name,
                                                 SBQQ__Product__r.Base_SKU__c,
                                                 SBQQ__Product__r.Name,
                                                 SBQQ__ProductCode__c,
                                                 Parent_Product_Code__c,
                                                 Extended_Regular_Unit_Price__c,
                                                 Product_Description__c,
                                                 Extended_List_Unit_Price__c,
                                                 SBQQ__Quantity__c,
                                                 SBQQ__StartDate__c,
                                                 SBQQ__EndDate__c,
                                                 Extended_Published_List_Price__c,
                                                 Total_List_Discount__c,
                                                 Final_Price2__c,
                                                 SBQQ__Quote__r.SBCF_Reseller__r.Record_Type__c,
                                                 SBQQ__Quote__r.SBCF_Reseller__r.Name,
                                                 SBQQ__Quote__r.Quote_Name__c,
                                                 SBCF_Serial_Number__c,
                                                 SBQQ__ProductOption__c,
                                                 SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c,
                                                 SBQQ__RequiredBy__r.Product_Description__c,
                                                 SBQQ__RequiredBy__c,
                                                 CurrencyIsoCode  // Aditya : Added as part of currency code
                                                 FROM SBQQ__QuoteLine__c 
                                                 WHERE SBQQ__Quote__c = :quoteId and Is_Optional__c = FALSE]);
  /**
     * SFDC-17202: Added an extra condition as Is_Optional__c = FALSE: 
     * **********  Added new fields Product_Description__c, Extended_List_Unit_Price__c to the query.
     * ********** END
     * */
    SBQQ__Quote__c renewedQuote = [SELECT
                                   SBQQ__Opportunity2__c,
                                   SBQQ__Opportunity2__r.Bill_To_Account__c,
                                   SBQQ__Opportunity2__r.Bill_To_Account__r.Name,
                                   Quote_Name__c,
                                   SBQQ__Account__c,
                                   SBQQ__Account__r.Name,
                                   Name //This is the quote number
                                   FROM SBQQ__Quote__c
                                   WHERE Id = :quoteId
                                   LIMIT 1
                                  ];
                                  
    System.debug('number of QuoteLines: ' + quoteLineIdMap.size());
    System.debug('serialQuoteLineMap' + serialQuoteLineMap);

    Set<Id> allParentQuoteIds = new Set<Id>();

    for(SBQQ__QuoteLine__c currentQL: quoteLineIdMap.values()) {

        Boolean quoteLineVisibility = String.isNotBlank(currentQL.SBQQ__ProductOption__c) && currentQL.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c == 'Never' ? false : true;

        if(quoteLineVisibility || 
            (!quoteLineVisibility && !allParentQuoteIds.contains(currentQL.SBQQ__RequiredBy__c)))
        {

          System.debug('Contains Key: ' + serialQuoteLineMap.containsKey(currentQL.SBCF_Serial_Number__c));
          if(!serialQuoteLineMap.containsKey(currentQL.SBCF_Serial_Number__c)) {
            SerialDetail newSerialInstance = new SerialDetail();
            newSerialInstance.Id = currentQL.SBCF_Serial_Number__c;
            newSerialInstance.serialNumber = currentQL.SBCF_Serial_Number__c;
            System.debug('New Serial Number: ' + currentQL.SBCF_Serial_Number__c);
            System.debug('New Serial Instance: ' + newSerialInstance);
            serialQuoteLineMap.put(newSerialInstance.Id, new List<QuoteLineDetail>());
            serialDetails.add(newSerialInstance);
          }
          QuoteLineDetail quoteLineInstance = new QuoteLineDetail();
          quoteLineInstance.endUserName = currentQL.SBQQ__Quote__r.SBQQ__Opportunity2__r.Account.Name;
          
        /**
         * SFDC-17202: Replaced SBQQ__Product__r.name with Product_Description__c
         * **********  Added a new field Extended_List_Unit_Price__c.
         * *********** START
         * */
          //quoteLineInstance.product = currentQL.SBQQ__Product__r.name;
          String prodDescription = quoteLineVisibility?currentQL.Product_Description__c:currentQL.SBQQ__RequiredBy__r.Product_Description__c;
          String prodCode = quoteLineVisibility?currentQL.SBQQ__ProductCode__c: currentQL.Parent_Product_Code__c;

          quoteLineInstance.product = prodDescription;
          quoteLineInstance.SKU = prodCode;
          quoteLineInstance.listUnitPrice = currentQL.Extended_Regular_Unit_Price__c;
        /**
         * SFDC-17202: Replaced SBQQ__Product__r.name with Product_Description__c
         * **********  Added a new field Extended_List_Unit_Price__c.
         * *********** END
         * */
          quoteLineInstance.quantity = Integer.valueOf(currentQL.SBQQ__Quantity__c);
          quoteLineInstance.startDate = currentQL.SBQQ__StartDate__c;
          quoteLineInstance.endDate = currentQL.SBQQ__EndDate__c;
          quoteLineInstance.extListPrice = currentQL.Extended_Published_List_Price__c;
          if(currentQL.Total_List_Discount__c != null) {
            quoteLineInstance.totalListDisc = currentQL.Total_List_Discount__c / 100;
          }
          quoteLineInstance.extFinalPrice = currentQL.Final_Price2__c;
          quoteLineInstance.resellerAccountType = currentQL.SBQQ__Quote__r.SBCF_Reseller__r.Record_Type__c;
          quoteLineInstance.resellerAccountName = currentQL.SBQQ__Quote__r.SBCF_Reseller__r.Name;
          quoteLineInstance.currencyIsoCode = currentQL.CurrencyIsoCode;  // Aditya : Added as part of currency code
          serialQuoteLineMap.get(currentQL.SBCF_Serial_Number__c).add(quoteLineInstance);

          allParentQuoteIds.add(quoteLineVisibility?currentQL.Id:currentQL.SBQQ__RequiredBy__c);
        }
    }
    data.quote = renewedQuote;

    for(SerialDetail serial : serialDetails) {
      List<QuoteLineDetail> quoteLines = serialQuoteLineMap.get(serial.Id);
      serial.subs = quoteLines;
    }

    data.serials = serialDetails;
    System.debug('data quote: ' + data.quote);
    System.debug('data serial: ' + data.serials);
    return data;
  }

  @AuraEnabled(cacheable=true)
  public static SBQQ__Quote__c getBillingShippingAddresses( String quoteId ) {
    System.debug('quoteId: ' + quoteId);
    SBQQ__Quote__c quoteRecord = [SELECT 
                                    Shipping_Address__c,
                                    Shipping_Address__r.Account__r.Name,
                                    Shipping_Address__r.Street__c,
                                    Shipping_Address__r.State__r.Name,
                                    Shipping_Address__r.City__c,
                                    Shipping_Address__r.Zip_Postal_Code__c,
                                    Shipping_Address__r.Country__r.Name,
                                    Billing_Address__c,
                                    Billing_Address__r.Account__r.Name,
                                    Billing_Address__r.Account__r.Bill_To_Email__c,
                                    Billing_Address__r.Street__c,
                                    Billing_Address__r.State__r.Name,
                                    Billing_Address__r.City__c,
                                    Billing_Address__r.Zip_Postal_Code__c,
                                    Billing_Address__r.Country__r.Name
                                  FROM SBQQ__Quote__c
                                  WHERE Id = :quoteId];
    return quoteRecord;
  }


  // Aditya - Added as part of SFDC-16916
  /*@AuraEnabled(cacheable=true)
  public static List<Address__c> getAddresses( String accountId, String quoteId) {
    return [SELECT Id, Name, Account_Name__c, Street__c, City__c, State_ISO__c, Country__c, Zip_Postal_Code__c, Type__c, Primary__c FROM Address__c WHERE Account__c = :accountId];
  }*/

  // Aditya - Added as part of SFDC-16916
  @AuraEnabled(cacheable=true)
  public static List<Credit_Card__c> getCreditCards() {
    List<Credit_Card__c> creditCardList = new List<Credit_Card__c>();
    User userRecord = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
    List<Contact> conList = [SELECT Id, Name, Account.Name ,Account.isPartner, Accountid FROM Contact WHERE Id = :userRecord.ContactId LIMIT 1];
    System.debug(conList);
    if(conList !=null && conList.size()>0){
      creditCardList = [SELECT ID, Last_4_of_CC__c, tolabel(Card_Type__c), Expiration__c
                FROM Credit_Card__c
                WHERE Account__c = :conList[0].accountId];
    }
    else{
      System.debug('no conacts...');
      creditCardList = null;
    }
    return creditCardList;
  }

  // Aditya - Added as part of SFDC-16916
  @AuraEnabled(cacheable=false)
  public static boolean validPONumber( String poNumber, String accountId, String quoteId) {
    List<Opportunity> opptyList = [SELECT Id,PurchaseOrderID__c,PO_OK__c,StageName,Bill_To_Account__c FROM Opportunity WHERE SBQQ__PrimaryQuote__c = :quoteId];

    if(!opptyList.isEmpty()) {
      accountId = opptyList[0].Bill_To_Account__c;
    }
	
    List<Opportunity> foundOpps = [SELECT Id FROM Opportunity WHERE AccountId = :accountId AND StageName = 'Closed Won' AND PurchaseOrderID__c = :poNumber];
	
    return foundOpps.isEmpty();
  }
    
  public class SerialQuoteLineDetail{

    @AuraEnabled

    public SBQQ__Quote__c quote {get; set;}
    
    @AuraEnabled 
    public List<SerialDetail> serials {get; set;}

    public SerialQuoteLineDetail(){}
  }

  public class SerialDetail{
    
    @AuraEnabled
    public String id {get; set;}

    @AuraEnabled
    public String serialNumber {get; set;}

    @AuraEnabled
    public List<QuoteLineDetail> subs {get; set;}

    public SerialDetail(){}

    // public SerialDetail(String Id,
    //                     String serialNumber
    //                     ) {
    //   this.id = Id;
    //   this.serialNumber = serialNumber;
    // }
  }

  public class QuoteLineDetail{

    @AuraEnabled
    public String endUserName {get; set;}
    @AuraEnabled
    public String accountId {get; set;}
    @AuraEnabled
    public String opportunityId {get; set;}
    @AuraEnabled
    public String quoteName {get; set;}
    @AuraEnabled
    public String SKU {get; set;}
    @AuraEnabled
    public String product {get; set;}
    //SFDC-17202: Added a new field as listUnitPrice: START
    @AuraEnabled
    public Decimal listUnitPrice {get; set;}
    //SFDC-17202: Added a new field as listUnitPrice: END
    @AuraEnabled
    public Integer quantity {get; set;}
    @AuraEnabled
    public Date startDate {get; set;}
    @AuraEnabled
    public Date endDate {get; set;}
    @AuraEnabled
    public Decimal extListPrice {get; set;}
    @AuraEnabled
    public Decimal totalListDisc {get; set;}
    @AuraEnabled
    public Decimal extFinalPrice {get; set;}
    @AuraEnabled
    public String resellerAccountType {get; set;}
    @AuraEnabled
    public String resellerAccountName {get; set;}
    @AuraEnabled
    public String currencyIsoCode {get; set;} // Aditya : Added as part of currency code

    public QuoteLineDetail(){}
    //SFDC-17202: Added a new field as listUnitPrice: START
    // public QuoteLineDetail(String endUserName,
    //                        String SKU,
    //                        String product,
    //                        Decimal listUnitPrice,
    //                        Integer quantity,
    //                        Date startDate,
    //                        Date endDate,
    //                        Decimal extListPrice,
    //                        Decimal totalListDisc,
    //                        Decimal extFinalPrice,
    //                        String resellerAccountType,
    //                        String resellerAccountName) {
    //   this.endUserName = endUserName;
    //   this.SKU = SKU;
    //   this.product = product;
    //   this.listUnitPrice = listUnitPrice;
    //   //SFDC-17202: Added a new field as listUnitPrice: END
    //   this.quantity = quantity;
    //   this.startDate = startDate;
    //   this.endDate = endDate;
    //   this.extListPrice = extListPrice;
    //   this.totalListDisc = totalListDisc;
    //   this.extFinalPrice = extFinalPrice;
    //   this.resellerAccountType = resellerAccountType;
    //   this.resellerAccountName = resellerAccountName;
    // }
  }

  //Additional Functions for SFDC-17142
  /*
    processOrder
    pollJob
  */
  @AuraEnabled(cacheable=true)
  public static Id processOrder(String quoteId, String selectedCreditCard, String poNumber, Boolean autoRenew) {
    System.debug('Processing new Order');
    Id jobId = System.enqueueJob(new RenewalCheckoutQuoteOrderedQueueable(quoteId, selectedCreditCard, poNumber, autoRenew));
    return jobId;
  }

  // //pollJob 
  // //polls for Job with matching Id and returns a process status value
  @AuraEnabled(cacheable=false)
  public static String pollJob(String jobId) {
    AsyncApexJob jobInfo = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];
    //Filter down possible statuses
    if(jobInfo.Status == 'Completed') {
      return 'Success';
    } else if (jobInfo.Status == 'Failed') {
      return 'Failed';
    } else {
      return 'Processing';
    }
  }
}