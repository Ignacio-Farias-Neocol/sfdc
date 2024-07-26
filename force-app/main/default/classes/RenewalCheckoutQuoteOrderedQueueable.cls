//SFDC-17142
//Custom Queueable Object to create an Order 
public without sharing class RenewalCheckoutQuoteOrderedQueueable implements Queueable {
    
    //Member variables
    public String quoteId;
    public String selectedCreditCard;
    public String poNumber;
    public Boolean autoRenew;

    //Construtor to populate member variables
    public RenewalCheckoutQuoteOrderedQueueable(String quoteId, String selectedCreditCard, String poNumber, Boolean autoRenew){
        this.quoteId = quoteId;
        this.selectedCreditCard = selectedCreditCard;
        this.poNumber = poNumber;
        this.autoRenew = autoRenew;
    }

    public void execute(QueueableContext context) {

        try{
            quoteOrdered();
        } catch (Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
            LogModel.singleLog('RenewalCheckoutHelper', 'processOrderAsync. Error: ' + e.getStackTraceString(), LogModel.LOG_CATEGORY_APEX);
            throw e;
        }

    }

    public void quoteOrdered(){

        DynamicBusinessRuleOpptyCoreAfter.isAlreadyQueued = true;

        SBQQ__Quote__c quote = [
            SELECT
            Id,
            SBQQ__Account__c,
            ApprovalStatus__c
            FROM SBQQ__Quote__c
            WHERE Id = :this.quoteId
        ];

        Opportunity opp =   [
            SELECT
            Id,
            OwnerId,
            AccountId,
            SBCF_Billing_Aggregator__c,
            Deal_Reg_Type__c,
            Distributor__c,
            CloseDate,
            Legacy_Data__c,
            Reseller__c,
            Select_Primary_Contact__c,
            Billing_Address__c,
			Shipping_Address__c,
            CurrencyIsoCode
            FROM Opportunity
            WHERE SBQQ__PrimaryQuote__c = :this.quoteId
            LIMIT 1
            ];
        
        quote.SBQQ__Account__c           = opp.AccountId;
        quote.SBCF_Billing_Aggregator__c = opp.SBCF_Billing_Aggregator__c;
        quote.Closed_Date__c             = Date.today();
        /**
         * Changes done as a part of SFDC-18161: START
         */
        //quote.SBCF_Deal_Reg_Type__c      = opp.Deal_Reg_Type__c;
        quote.SBCF_Deal_Reg_Type2__c      = opp.Deal_Reg_Type__c;
        /**
         * Changes done as a part of SFDC-18161: END
         */
        quote.SBQQ__Distributor__c       = opp.Distributor__c;
        quote.Legacy_Data__c             = opp.Legacy_Data__c;
        quote.CurrencyIsoCode            = opp.CurrencyIsoCode;
        quote.SBCF_Reseller__c           = opp.Reseller__c;
        quote.SBQQ__PrimaryContact__c    = opp.Select_Primary_Contact__c;
        quote.Billing_Address__c         = opp.Billing_Address__c;
        quote.Shipping_Address__c        = opp.Shipping_Address__c;
        quote.SBCF_Order_Type__c         = 'Renewal';
        quote.SBQQ__Type__c              = 'Renewal';
        quote.Available_on_Portal__c     = true;
        
        update quote;
        
        quote = [
            SELECT
            Id,
            SBQQ__Account__c,
            ApprovalStatus__c
            FROM SBQQ__Quote__c
            WHERE Id = :this.quoteId
        ];

        if(quote.ApprovalStatus__c != 'Approved') {
            quote.ApprovalStatus__c = 'Approved';
            quote.SBQQ__Status__c = 'Approved';
            update quote;
        }

        //Payment is either by CC or poNumber
        if (selectedCreditCard != null) {
            opp.Bill_To_Credit_card__c = this.selectedCreditCard;
        } else {
            opp.PurchaseOrderID__c = this.poNumber;
        }
        
        opp.stageName = 'Closed Won';
        //Missing automation piece. What triggers opp.SBQQ__Ordered__c to true after stageName is set to 'Closed Won'
        // opp.SBQQ__Ordered__c = true;
        update opp;

        // Only enqueue the next job if tests are not running
        if(!Test.isRunningTest()) {
            System.enqueueJob(new RenewalCheckoutOrderActivatedQueueable(opp.Id, autoRenew));
        }
    }
}