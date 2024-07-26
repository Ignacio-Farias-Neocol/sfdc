/**
* @author Salesforce Services
* @date 03/02/2020
*
* @group Lightning Component Helper
*
* @description Helper class for the Product List View component. Created as part of SFDC-9682
*
*/
public without sharing class ProductListViewHelper {

  //Get Serial details for the logged in user Id
  @AuraEnabled(cacheable=true)
  public static ProductListViewHelper.SerialSubDetail getSerialSubDetails(String entityId, 
                                                                          String accountType) {

    //Check the type of entity being set
    String objectName = Id.valueOf(entityId).getSobjectType().getDescribe().getName();
    
    //Account Id variable
    String accountId;

    //If the Objectname is user then get the account Id else call the account method
    if(objectName.equalsIgnoreCase('User')){
      //Get the user information using the logged in user Id
      User communityUser = [Select Contact.AccountId from User where Id = :entityId];

      //User Account Id
      accountId = communityUser.Contact.AccountId;
    }
    else{
      accountId = entityId;
    }

    //Return Serials
    return getSerialSubDetailsUsingAccountId(accountId, accountType);
  }

  //Get Serial details for the logged in user Id
  @AuraEnabled(cacheable=true)
  public static ProductListViewHelper.SerialSubDetail getSerialSubDetailsUsingAccountId(String accountId, 
                                                                                        String accountType) {

    //Map of SKU number and serial Id. 
    //This is needed to get the product name and populate that name in ProductListViewHelper.SerialDetail instance
    Map<String, Set<String>> serialProductNameMap = new Map<String, Set<String>>();

    //Map of serial Id and ProductListViewHelper.SerialDetail instance
    Map<String, ProductListViewHelper.SerialDetail> serialMap = new Map<String, ProductListViewHelper.SerialDetail>();

    //Map of serial Id and ProductListViewHelper.SubDetail instance
    Map<String, List<ProductListViewHelper.SubDetail>> serialSubMap = new Map<String, List<ProductListViewHelper.SubDetail>>();

    //Resolving for SOQL Injection so Sanitizing the AccountType
    String sanitizedAccountType = String.escapeSingleQuotes(accountType);


    //Serial Query
    String query = 'SELECT ' + 
                   'Serial__c,' +
                   //Added as a part of SFDC-16035: START
                   'End_User_Account__c,' +
                   'End_User_Account__r.Business_Group__c,'+
                   //Added as a part of SFDC-16035: END
                   'Serial__r.Serial_Number__c, Subscription__r.SBQQ__RequiredByProduct__r.Description,Subscription__r.SBQQ__ProductOption__c, Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c, Subscription__r.SBQQ__RequiredById__c,' +
                   'Serial__r.Business_Group__c,' +
                   'Serial__r.Base_Product_SKU__c,' + 
                   'Subscription__r.SBQQ__Contract__c,' +
                   'Subscription__r.SBQQ__Contract__r.ContractNumber,' + 
                   'Subscription__r.SBQQ__Contract__r.Reseller__r.Name,' +
                   'Subscription__r.SBQQ__Contract__r.Distributor__r.Name,' +
                   'Subscription__r.SBQQ__Contract__r.EndDate,' +
                   'Subscription__r.SBQQ__ProductName__c,' +
                   //Added as a part of SFDC-16472: START
                   'Subscription__r.Product_Description__c,'+
                   'Subscription__r.Core_License_Usage__c,'+
                   //Added as a part of SFDC-16472: END
                   'Subscription__r.Current_Quantity__c,' +
                   'Subscription__r.SBQQ__Quantity__c,' +
                   'Subscription__r.SBQQ__SubscriptionStartDate__c,' +
                   'Subscription__r.SBQQ__SubscriptionEndDate__c,' +
                   'Subscription__r.AnnotationReason__c'+
                   ' FROM Assigned_Serial__c' + 
                   ' WHERE Subscription__c !=null' +
                   ' AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:3' + 
                   ' AND Subscription__r.SBQQ__RevisedSubscription__c=null' + 
                   ' AND Subscription__r.Has_Not_Been_Renewed__C = true';

    System.debug('***Account Type: '+ sanitizedAccountType);
    //Based on the account type determine the account field to be used for getting serials
    if(String.isNotBlank(sanitizedAccountType)){
      switch on sanitizedAccountType {
        when 'Customer' {
          query += ' AND Subscription__r.SBQQ__Account__c = :accountId';
        }
        when 'Reseller' {
          //Reseller is currently using the same field. Keeping it separate to allow for future changes.
          query += ' AND Subscription__r.SBQQ__Account__c = :accountId';
        }
        when 'Internal' {
          //Internal is currently using the same field. Keeping it separate to allow for future changes.
          query += ' AND Subscription__r.SBQQ__Account__c = :accountId';
        }        
        //By default Subscription Account Id is used
        when else{
          query += ' AND Subscription__r.SBQQ__Account__c = :accountId';
        }
      }
    }

    //Adding Order By Clause
    query +=  ' ORDER BY Serial__r.Serial_Number__c';

    System.debug('QUERY: ' + query);

    Set<Id> allSubIds = new Set<Id>();

    //Prepare a map of Product code and Serial Ids with that Product code
    //Prepare a map of Serial Id and ProductListViewHelper.SerialDetail instance
    for(Assigned_Serial__c currentAS: Database.query(query))    
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
            String contractPartner = (sanitizedAccountType == 'Reseller')? currentAS.Subscription__r.SBQQ__Contract__r.Distributor__r.Name: currentAS.Subscription__r.SBQQ__Contract__r.Reseller__r.Name;
          
          //Added as a part of SFDC-16035: START
          String customer360 = '';
          if(String.isNotBlank(currentAS.End_User_Account__c) && (String.isNotBlank(currentAS.Serial__r.Serial_Number__c))){
            customer360 = System.Label.Customer_360_on_Account_Link+String.valueOf(currentAS.End_User_Account__c)+'#'+String.valueOf(currentAS.Serial__r.Serial_Number__c);
          }
          System.debug('customer360 is:'  +customer360);
            //Added as a part of SFDC-16035: END       
            /* START: Prepare SerialMap */
            if(serialMap!=null){
              if(serialMap.containsKey(serialId)){
                ProductListViewHelper.SerialDetail existingSerialInstance = serialMap.get(serialId);

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
                existingSerialInstance.status = getEntityStatus(existingSerialInstance.contractEndDate,null);

                //Get status number. This will be used for sorting
                existingSerialInstance.statusNumber = existingSerialInstance.status == 'ACTIVE'? 1: (existingSerialInstance.status == 'RENEW'? 2:3);

                //Icon Detail
                existingSerialInstance.iconDetail = prepareIconDetails(existingSerialInstance.status);
              }
              else{
                ProductListViewHelper.SerialDetail newSerialInstance = new ProductListViewHelper.SerialDetail(basesku,
                                                                                                              contractEndDate,
                                                                                                              serialId,
                                                                                                              contractPartner,
                                                                                                              1,
                                                                                                              currentAS.Serial__r.Serial_Number__c,
                                                                                                              currentAS.Serial__r.Business_Group__c,
                                                          //Added as a part of SFDC-16035: START
                                                          customer360
                                                          //Added as a part of SFDC-16035: END
                                                                                                              );
                  System.debug('newSerialInstance is:' +newSerialInstance);                                                                                            
                //Determine Serial status
                newSerialInstance.status = getEntityStatus(newSerialInstance.contractEndDate,null);

                //Get status number. This will be used for sorting
                newSerialInstance.statusNumber = newSerialInstance.status == 'ACTIVE'? 1: (newSerialInstance.status == 'RENEW'? 2:3);

                //Icon Detail
                newSerialInstance.iconDetail = prepareIconDetails(newSerialInstance.status);

                serialMap.put(serialId, newSerialInstance);
                System.debug('serialMap is:' +serialMap);  
              }
            }
            /* END: Prepare SerialMap */

            /* START: Prepare serialProductNameMap */
			//SFDC-18413: Added basesku!='' check as inactive product going as bundle
            if(serialProductNameMap!=null && basesku!=''){                                                       
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

              //Build the sub object
              ProductListViewHelper.SubDetail subInstance = new ProductListViewHelper.SubDetail(currentAS.Subscription__c,
                                                                                                //Added as a part of SFDC-16472: START
                                                                                                //currentAS.Subscription__r.SBQQ__ProductName__c,
                                                                                                prodDescription,
                                                                                                //Added as a part of SFDC-16472: END
                                                                                                quantity,
                                                                                                currentAS.Subscription__r.SBQQ__SubscriptionStartDate__c,
                                                                                                currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c,
                                                                                                currentAS.Subscription__r.SBQQ__Contract__r.ContractNumber,
                                                                                                currentAS.Subscription__r.AnnotationReason__c,
                                                                                                currentAS.Subscription__r.SBQQ__Contract__c
                                                                                                //currentAS.Subscription__r.Core_License_Usage__c
                                                                                                );
              //Determine Sub status
              subInstance.status = getEntityStatus(subInstance.subEndDate,quantity);

              //Get status number. This will be used for sorting
              subInstance.statusNumber = subInstance.status == 'ACTIVE'? 1: (subInstance.status == 'RENEW'? 2:3);
              
              //Icon Detail
              subInstance.iconDetail = prepareIconDetails(subInstance.status);     

              if(serialSubMap.containsKey(serialId)){
                serialSubMap.get(serialId).add(subInstance);
              }
              else{
                //Add it to the map
                serialSubMap.put(serialId, new List<ProductListViewHelper.SubDetail>{subInstance});
              }
            }
            /* END: Prepare SerialSubMap */

            allSubIds.add(quoteLineVisibility?currentAS.Subscription__c:currentAS.Subscription__r.SBQQ__RequiredById__c);
        }
    }

    //Get the Product Name using the base product SKU
	//SFDC-18413: Added productcode!=nullcheck as inactive product coming
    for(Product2 currentProduct: [SELECT Name,
                                         Base_SKU__c,
                                         ProductCode 
                                  FROM Product2
                                  WHERE productcode in :serialProductNameMap.keySet() and productcode!=null]){
      //Loop through products and assign name in the Serial object instance
      if(serialProductNameMap.containsKey(currentProduct.ProductCode.toLowerCase())){
        for(String currentSerial : serialProductNameMap.get(currentProduct.ProductCode.toLowerCase())){
          serialMap.get(currentSerial).productName = currentProduct.Name;
        }
      }
    }
    
    System.debug('Serials Size: ' + serialMap.size());
    return new ProductListViewHelper.SerialSubDetail(serialMap.values(), serialSubMap);
  }  
  /*Fetch Subscription details based on the serial Id
    This method is currently not being used*/
  @AuraEnabled(cacheable=true)
  public static List<ProductListViewHelper.SubDetail> getSubscriptions(String serialId) {

    //Get Assigned Serials using the Serial Id
    if(String.isNotBlank(serialId)){
      //List to be returned
      List<ProductListViewHelper.SubDetail> subList = new List<ProductListViewHelper.SubDetail>();
      for(Assigned_Serial__c currentAS: [SELECT Subscription__c, 
                                                Subscription__r.SBQQ__ProductName__c,
                                                Subscription__r.SBQQ__Quantity__c,
                                                Subscription__r.Current_Quantity__c,
                                                Subscription__r.SBQQ__SubscriptionStartDate__c,
                                                Subscription__r.SBQQ__SubscriptionEndDate__c,
                                                Subscription__r.Active__c,
                                                Subscription__r.SBQQ__Contract__r.ContractNumber,
                                                Subscription__r.AnnotationReason__c,
                                                Subscription__r.SBQQ__Contract__c
                                          FROM Assigned_Serial__c 
                                          WHERE Serial__c = :serialId 
                                          AND Subscription__c!=null]){
        
        //Build the sub object
        ProductListViewHelper.SubDetail subInstance = new ProductListViewHelper.SubDetail(currentAS.Subscription__c,
                                                                                             currentAS.Subscription__r.SBQQ__ProductName__c,
                                                                                             Integer.valueOf(currentAS.Subscription__r.SBQQ__Quantity__c),
                                                                                             currentAS.Subscription__r.SBQQ__SubscriptionStartDate__c,
                                                                                             currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c,
                                                                                             currentAS.Subscription__r.SBQQ__Contract__r.ContractNumber,
                                                                                             currentAS.Subscription__r.AnnotationReason__c, 
                                                                                             currentAS.Subscription__r.SBQQ__Contract__c
                                                                                             );

        Decimal quantity = currentAS.Subscription__r.Current_Quantity__c !=null ? currentAS.Subscription__r.Current_Quantity__c : currentAS.Subscription__r.SBQQ__Quantity__c;
        
        //Determin Sub status
        subInstance.status = getEntityStatus(subInstance.subEndDate,quantity);

        //Add to the return list
        subList.add(subInstance);
      }
      if(subList!=null && !subList.isEmpty()){
        return subList;
      }
      else{
        return null;
      }
    }
    else{
      return null;
    }
  }

  /*Method to get the Visualforce page url for showing certificate
    The method expects the Visualforce page API name*/
  @AuraEnabled(cacheable=true)
  public static String getUrl(String pageName) {

    if(String.isNotBlank(pageName)){
      String urlSuffix = '/apex/' + pageName;
      //Check if the request is from community
      if(System.Site.getSiteType()==null){
        return URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+pageName;
      } 
      else{
        return System.Site.getBaseUrl()+'/apex/' + pageName;
      }     
    }
    else{
      return null;
    }
  }  

  /*Method to get the Visualforce page url for showing certificate
    The method expects the Visualforce page API name*/
  @AuraEnabled
  public static String getUrlcert(String pageName,String serialId) {
    System.debug('***serial***: '+ serialId);
      boolean bcheck = SerialAccesscheck(serialId);
       if(bcheck == true){
        if(String.isNotBlank(pageName)){
          String urlSuffix = '/apex/' + pageName;
          //Check if the request is from community
          if(System.Site.getSiteType()==null){
            return URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+pageName;
          } 
          else{
            return System.Site.getBaseUrl()+'/apex/' + pageName;
          }     
        }
    
    else{
      return null;
    }
    }else{
      return null;
    }
  }  

  public static Boolean SerialAccesscheck(String serialId){ System.debug(serialId+'****');
      List<Serial__Share> sharerecords = new List<Serial__Share>();
      
      Serial__c record = [Select Id from Serial__c where Id=:serialId limit 1];
      
      List<Serial__share> listshare = [Select Id from Serial__share where UserorGroupId =: UserInfo.getUserId() and 
                                          ParentId =: serialId];
                                          
      if(listshare!=null && !listshare.IsEmpty()){
          return true;
      }else{
        Serial__share oshare = new Serial__share(UserorGroupId =UserInfo.getUserId(),ParentId = serialId,RowCause=Schema.Serial__share.RowCause.Community_Share__c, AccessLevel='Edit');

        sharerecords.add(oshare);
        System.debug('*****'+sharerecords);
        Database.Insert(sharerecords);
        return true;
      }                     
  }

  /* Gets the status value based on the date passed */
  private static String getEntityStatus(Date endDate, Decimal qty){
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
    //SFDC-15635
    if(qty != null && qty == 0){
      status = 'INACTIVE';
    }
    //SFDC-15635
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
    public List<ProductListViewHelper.SerialDetail> serials;

    //Subscription for each serial
    @AuraEnabled
    public Map<String, List<ProductListViewHelper.SubDetail>> serialSubMap;

    public SerialSubDetail(List<ProductListViewHelper.SerialDetail> serials, 
                           Map<String, List<ProductListViewHelper.SubDetail>> serialSubMap){
      
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
    
    //Added as a part of SFDC-16035: START
    @AuraEnabled
    public String customer360;
    //Added as a part of SFDC-16035: END

    public SerialDetail(String baseProductSKU, 
                        Date contractEndDate,
                        String id,
                        String partner,                        
                        Integer quantity,
                        String serialNumber,
                        String businessGroup,
                        //Added as a part of SFDC-16035: START
                        String customer360){
                        //Added as a part of SFDC-16035: END
      
      this.baseProductSKU   = baseProductSKU;
      this.contractEndDate  = contractEndDate;
      this.id               = id;
      this.partner          = partner;
      this.productName      = productName;
      this.quantity         = quantity;
      this.serialNumber     = serialNumber;
      this.businessGroup    = businessGroup;
      //Added as a part of SFDC-16035: START
      this.customer360        = customer360;
      //Added as a part of SFDC-16035: END
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
    public String coreLicenseUsage;  // Aditya - Added as part of SFDC-18330
    
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

    public SubDetail(String id,
                     String productName,
                     Decimal quantity,
                     Date subStartDate,                       
                     Date subEndDate, 
                     String contractNumber,
                     String AnnotationReason,
                     String contractId){
      
      this.id           = id;
      this.productName  = productName;
      this.quantity     = quantity;
      this.subStartDate = subStartDate;
      this.subEndDate   = subEndDate;
      this.contractNumber = contractNumber;
      this.AnnotationReason = AnnotationReason;
      this.contractId   = contractId;
     // this.coreLicenseUsage = coreLicenseUsage;  // Aditya - Added as part of SFDC-18330
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