/**
* @author Salesforce Services
* @date 03/15/2020
*
* @group VF page extension Helper
*
* @description Extension for subscription cert for serials. SFDC-11483.
* Modification: SFDC-14547 > Added filter for Subs to filter out records using 
*               SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c.
*
*/
public without sharing class SubscriptionCertificateExtension {

  private final String accountName;
  // private List<Assigned_Serial__c> subs;

  //Determines if cert is being launched from Customer or partner community
  private final String accountType = ApexPages.currentPage().getParameters().get('accountType');

  //private final String partnerName = ApexPages.currentPage().getParameters().get('partner');

  /*SFDC-14547: Commenting the logic to fetch account since Account field has been added to Serial.
    Account information will now be pulled from this field*/
  //Gets the account Id passed in the parameter
  // private final String accountId = ApexPages.currentPage().getParameters().get('aId');

  //controls how many Subscription items are displayed on page 1
  private final Integer firstBreak;
  
	//controls how many Subscription items are displayed on subsequent pages
 	private final Integer subseqBreak;
   
  //list of subs array for each page
 	private List<SubscriptionWrapper[]> pageBrokenSubs;

  //Set of sub Ids to be shown on the cert
 	private Set<Id> allSubIds = new Set<Id>();

  private String partnerName;

  /*SFDC-14547: Commenting the logic to fetch account since Account field has been added to Serial.
  Account information will now be pulled from this field*/
  //get account name
  // public String getAccountName() {
  //   return accountName;
  // }

  //get number of lines for first page
  public Integer getFirstBreak() {
    return firstBreak;
  }

  //get number of lines for other pages
  public Integer getSubseqBreak() {
    return subseqBreak;
  }
  
  public List<SubscriptionWrapper[]> getSubsArray() {
    system.debug('Number of pages: ' + pageBrokenSubs.size());
    return pageBrokenSubs;
  }

  public String getPartnerLabel() {
    String fieldLabel = (accountType == 'Reseller')? 'Distributor' : 'Partner';
    return fieldLabel;
  }

  public String getPartnerName() {
    System.debug('partnerName...'+partnerName);
    return partnerName;
  }

  private Serial__c ser;

  public Serial__c getSerial(){
    return ser;
  }

  public SubscriptionCertificateExtension(ApexPages.StandardController controller) {
    /*SFDC-14547: Commenting the logic to fetch account since Account field has been added to Serial.
    Account information will now be pulled from this field*/
    //If AccountId is passed then this is used for internal purpose
    // if(String.isNotBlank(accountId)){
    //   //Get the account and then the name
    //   List<Account> acct = [Select Name from Account where Id= :accountId];
    //   if(acct!=null && !acct.isEmpty()){
    //     accountName = acct[0].Name;
    //   }
    // }

    string serialId = controller.getRecord().Id;
    if(serialId != null ){
      List<Serial__c> serials = [Select Id, Order__r.PoNumber, Order__r.SBQQ__Quote__r.Name from Serial__c where Id =: serialId];
      ser = serials[0];
    }
    //Get community user to get the account name
    if(!Test.isRunningTest()){
      User communityUser = [select Account.Name from user where id=:userinfo.getuserid()];
      accountName = communityUser.Account.Name;
    }

    //Get number of lines for the pages
    List<Sub_Cert_Settings__mdt> certSettings = [SELECT First_Page_Lines__c,
                                                        Subsequent_Page_Lines__c
                                                 FROM Sub_Cert_Settings__mdt 
                                                 WHERE DeveloperName='Default'];

    firstBreak  = certSettings!=null && !certSettings.isEmpty()? (Integer)certSettings[0].First_Page_Lines__c:8;
    subseqBreak = certSettings!=null && !certSettings.isEmpty()? (Integer)certSettings[0].Subsequent_Page_Lines__c:20;

    //Get Serial Id
    //String serialId = controller.getRecord().id;
    populateSubs(serialId);
  }

  private void populateSubs(String serialId){

    //Initialize the list that will be using to paginate
    pageBrokenSubs = new List<SubscriptionWrapper[]>();

    //List of serials that will be used to draw table
    SubscriptionWrapper[] pageOfSubs = new SubscriptionWrapper[]{};
    Integer counter = 0;

    //Indicates if we have crossed 1st page
    boolean firstBreakFound = false;

    system.debug('First Break ' + firstBreak);
    system.debug('Sub Break: ' + subseqBreak);

    //Loop through assigned serials to populate required arrays
    for(Assigned_Serial__c currentAS : [SELECT Subscription__r.SBQQ__SubscriptionStartDate__c,
                                               Subscription__r.SBQQ__SubscriptionEndDate__c,
                                               Subscription__r.SBQQ__Quantity__c,
                                               Subscription__r.Current_Quantity__c,
                                               /*Added as a part of SFDC-16472: START*/
                                               Subscription__r.Product_Description__c,
                                               Subscription__r.SBQQ__RequiredByProduct__r.Description,
                                               /*Added as a part of SFDC-16472: END*/
                                               Subscription__r.SBQQ__ProductName__c,
                                               Subscription__r.SBQQ__OptionLevel__c,
                                               Subscription__r.SBQQ__ProductOption__c,
                                               Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c,
                                               Subscription__r.SBQQ__RequiredById__c,
                                               Subscription__r.SBQQ__RequiredByProduct__r.Name,
                                               Subscription__r.SBQQ__Contract__r.Reseller__r.Name
                                        FROM Assigned_Serial__c 
                                        WHERE Serial__c = :serialId 
                                        AND Subscription__c !=null
                                        AND Subscription__r.SBQQ__SubscriptionEnddate__C>=Last_n_years:3
                                        AND Subscription__r.SBQQ__RevisedSubscription__c=null
                                        AND Subscription__r.Has_Not_Been_Renewed__c = true]){

      /**
       * 1. Check if we are still in the first page. The count for first page is different than that for other pages. 
       * 2. If yes, then continue adding it to the list for the table
       * 3. If we have crossed first page then add the array of first page to the list of pages.Reset the array to start next page.
       *    Check if the number of rows added in the next page array is greater than the subsequent page count. 
       *    If yes, then add this array to the list, reset the array and start the process again. 
       * 4. This will give the list of arrays of subs that is used in the cert page. 
       */
      //Only consider Subs that are parent subs or subs that have product options set to visible for the quote document

      //Determine the quoteline visibility
      Boolean quoteLineVisibility = String.isNotBlank(currentAS.Subscription__r.SBQQ__ProductOption__c) && 
                                    currentAS.Subscription__r.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c == 'Never' ? false : true;
      if(quoteLineVisibility || 
          (!quoteLineVisibility && !allSubIds.contains(currentAS.Subscription__r.SBQQ__RequiredById__c))){
        if(!firstBreakFound) //Still on the first page
        {
          if(counter < firstBreak) //Counter is less than first break then add AS to the array
          {
            SubscriptionWrapper sub = new SubscriptionWrapper();
            sub.subId = currentAS.Subscription__c;
            sub.startDate = currentAS.Subscription__r.SBQQ__SubscriptionStartDate__c;
            sub.endDate = currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c;
            //Added/Modified as a part of SFDC-16472: START
            //sub.quantity = currentAS.Subscription__r.SBQQ__Quantity__c == null? currentAS.Subscription__r.Current_Quantity__c : currentAS.Subscription__r.SBQQ__Quantity__c;
            sub.quantity = currentAS.Subscription__r.Current_Quantity__c == NULL ? currentAS.Subscription__r.SBQQ__Quantity__c : currentAS.Subscription__r.Current_Quantity__c;
            sub.productDescription = quoteLineVisibility?currentAS.Subscription__r.Product_Description__c:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Description;
            //Added/Modified as a part of SFDC-16472: END
            sub.productName = quoteLineVisibility?currentAS.Subscription__r.SBQQ__ProductName__c:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Name;
            pageOfSubs.add(sub);  
            allSubIds.add(quoteLineVisibility?currentAS.Subscription__c:currentAS.Subscription__r.SBQQ__RequiredById__c);
            counter++;	
          }
          if(counter == firstBreak) //Counter has hit the first break threshold. Reset everything.
          {
            firstBreakFound = true;
            counter = 0;
            pageBrokenSubs.add(pageOfSubs);
            pageOfSubs = new SubscriptionWrapper[]{};
          }	
        }
        else //On subsequent pages
        {
          if(counter < subseqBreak) //Adding to the current page
          { 
            SubscriptionWrapper sub = new SubscriptionWrapper();
            sub.subId = currentAS.Subscription__c;
            sub.startDate = currentAS.Subscription__r.SBQQ__SubscriptionStartDate__c;
            sub.endDate = currentAS.Subscription__r.SBQQ__SubscriptionEndDate__c;
            //Added/Modified as a part of SFDC-16472: START
            //sub.quantity = currentAS.Subscription__r.SBQQ__Quantity__c == null? currentAS.Subscription__r.Current_Quantity__c : currentAS.Subscription__r.SBQQ__Quantity__c;
            sub.quantity = currentAS.Subscription__r.Current_Quantity__c == NULL ? currentAS.Subscription__r.SBQQ__Quantity__c : currentAS.Subscription__r.Current_Quantity__c;
            sub.productDescription = quoteLineVisibility?currentAS.Subscription__r.Product_Description__c:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Description;
            //Added/Modified as a part of SFDC-16472: END
            sub.productName = quoteLineVisibility?currentAS.Subscription__r.SBQQ__ProductName__c:currentAS.Subscription__r.SBQQ__RequiredByProduct__r.Name;
            pageOfSubs.add(sub);  
            allSubIds.add(quoteLineVisibility?currentAS.Subscription__c:currentAS.Subscription__r.SBQQ__RequiredById__c);
            counter++;
          }
          if(counter == subseqBreak) //Threshold for this page reached. Reset everything
          {
            counter = 0;
            pageBrokenSubs.add(pageOfSubs);
            pageOfSubs = new SubscriptionWrapper[]{};
          }	
        }
      }
      this.partnerName = currentAS.Subscription__r.SBQQ__Contract__r.Reseller__r.Name;
    } //END OF ASSIGNED SERIAL LOOP

    //if we have finished looping and have some subs left lets assign them
    if(!pageOfSubs.isEmpty())
    pageBrokenSubs.add(pageOfSubs);
            
  }

  //Wrapper class for Subscription information
  public class SubscriptionWrapper {
    public Id subId {get;set;}
    public Date startDate {get;set;}
    public Date endDate {get;set;}
    public Decimal quantity {get;set;}
    public String productName {get;set;} 
    /*Added as a part of SFDC-16472: START*/
    public String productDescription {get; set;}
    /*Added as a part of SFDC-16472: END*/   
  }
}