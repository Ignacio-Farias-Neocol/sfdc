public with sharing class CPQ_OrderItemList_Controller {
    public Order record {get; set;}
    public String listtype {get; set;}
    public String getBaseURL() {
        return System.URL.getSalesforceBaseUrl().ToExternalForm();
    }
    
    /* SFDC-6772 Email Template Sample
    Please RMA the following serial:

    Serial #: . . . . . . . 784894  
    Original BOS Order #:  1467115   this is the order number BOS produced when Maestro sent the request; not sure this is really necessary
    RMA Reason: . . . . . .  Partner didn't use these seats and never really set it up for this end user  this is filled in by the PSM who is processing the return
    Model: . . . . . . . . Complete    this is the model name, the SKU would also be fine
    Quantity: . . . . . . . 1     this is the quantity of seats/mailboxes on the serial
    SMB Name………College Summit     this would be nice to have, but I don’t think it’s available until a later phase (can’t find the ticket # right now)


    RMA Number Needed: . . YES
    Send RMA To: . . . . . ICemail@intronis.com


    (I don’t think this next part is needed.  Instead, I’d like a link to the serial record if possible)


    Original Purchase PO Can Be Found Here: 
    https://barracuda.my.salesforce.com/0066000001nTLr1AAG
    */
    public List<SBQQ__QuoteLine__c> RMAReplaceSerials {
        get {
            if (RMAReplaceSerials == null) {
                RMAReplaceSerials = [Select ID, Name, SBQQ__Quote__c, SBCF_Order_Line_Type__c, SBQQ__ProductCode__c, SBQQ__ProductName__c, 
                                        SBQQ__UpgradedAsset__c, SBQQ__UpgradedAsset__r.BNCPQ_Serial__c, SBQQ__UpgradedAsset__r.BNCPQ_Serial__r.Serial_Number__c, 
                                        SBCF_Serial_Number__c, RMA_Reason__c, SBQQ__EffectiveQuantity__c, SBQQ__Quantity__c, Needs_Serial__c
                                    From SBQQ__QuoteLine__c 
                                    Where SBCF_Order_Line_Type__c like '%RMA Replace%' and 
                                        SBQQ__Quote__c =: record.SBQQ__Quote__c and 
                                        SBQQ__UpgradedAsset__c <> NULL];
            }
            return RMAReplaceSerials;
        }
        private set;
    }
}