/**
* @author Salesforce Services
* @date 02/18/2021
*
* @description Class containing invocable method to add negative lines for Renewal Uplevel Downlevel.
*              This class also updates Upsell/Downsell Subscription field on new quote lines after reconfiguration
*              This class is called by Quote_After_Save_Operations flow      
*/
public with sharing class CPQ_QLUpdateRenewal {
  @InvocableMethod (label='Add/Update Quotes on Renewal Upsell Downsell' description='Adds missing quote lines on renewals and updates subscription on new quote lines')
  //The input parameter needs to be a list for invocable methods, but this method will always get one Serial Id
  public static void updateQL(List<Id> quoteIdList){
    CPQ_UpsellDownsell.updateRenewalQuoteUpsellDownsell(quoteIdList);
  }
}