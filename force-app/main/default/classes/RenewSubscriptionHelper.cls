public without sharing class RenewSubscriptionHelper {

    @InvocableMethod(label='Approval Portal Generated Quote')
    public static void approveGeneratedQuote(List<String> quoteIds) {
        RenewSubscriptionHelper.approveQuote(quoteIds[0]);
    }

    @future
    public static void approveQuote(String quoteId) {        
        RenewSubscriptionHelper.makeQuoteAvailableOnPortal(quoteId);

        SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
    }

    @AuraEnabled
    public static RenewSubscriptionHelper.ContractQuoteIds getRenewalQuote(String serialId) {
        System.debug('The serialId is: ' + serialId);

        //Retrieve all Contracts from Assigned Serials of the given serial
        List<Assigned_Serial__c> assignedSerials = [
            SELECT
            Id,
            Subscription__r.SBQQ__Contract__c,
            Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c
            FROM Assigned_Serial__c
            WHERE Serial__c = :serialId
            AND Subscription__r.SBQQ__RenewedDate__c = null
            AND Subscription__c != null
            AND Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.IsClosed = false
            ORDER BY Subscription__r.SBQQ__Contract__r.EndDate DESC
        ];

        //Id of our main Contract if there are more than 1
        Id mainContract = null;
        Id mainQuote = null;

        //Get list of all Contracts tied to the given Serial
        List<Id> contractIds = new List<Id>();
        for(Assigned_Serial__c assignedSerial: assignedSerials) {
            contractIds.add(assignedSerial.Subscription__r.SBQQ__Contract__c);
            if (mainQuote == null) {
                if(assignedSerial.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__c != null) {
                    mainContract = assignedSerial.Subscription__r.SBQQ__Contract__c;
                    mainQuote = assignedSerial.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
                }
            }
        }

        Contract contract = new Contract();
        contract.Id = mainContract;
        
        ContractQuoteIds contractQuote = new ContractQuoteIds();
        contractQuote.contractId = mainContract;
        contractQuote.quoteId = mainQuote;

        if(mainQuote != null) {
            RenewSubscriptionHelper.makeQuoteAvailableOnPortal(mainQuote);

            return contractQuote;
        } else {
            //Create a Primary Quote for the Contract's Renewal Opportunity
            contract.SBQQ__RenewalQuoted__c = true;
            contract.Portal_Generated_Primary_Renewal_Quote__c = true;
            update contract;
        }
        return contractQuote;
    }

    @AuraEnabled
    public static String pollRenewalQuote(String contractId) {
        List<Contract> contract = [
            SELECT Id,
            SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c
            FROM Contract
            WHERE Id = :contractId
            AND SBQQ__RenewalQuoted__c = true
            LIMIT 1
        ];

        if(contract.size() > 0) {
            return contract[0].SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
        } else {
            return null;
        }

    }
    
    //Method is given a Serial Id and will renew all subscriptions that have not been renewed. 
    @AuraEnabled
    public static String renewSubscriptions(String serialId) {
        System.debug('The serialId is: ' + serialId);

        //Retrieve all Contracts from Assigned Serials of the given serial
        List<Assigned_Serial__c> assignedSerials = [
            SELECT
            Id,
            Subscription__r.SBQQ__Contract__c,
            Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c
            FROM Assigned_Serial__c
            WHERE Serial__c = :serialId
            AND Subscription__r.SBQQ__RenewedDate__c = null
            AND Subscription__c != null
            AND Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.IsClosed = false
            ORDER BY Subscription__r.SBQQ__Contract__r.EndDate DESC
        ];

        //Id of our main Contract if there are more than 1
        Id mainContract = null;
        Id mainQuoteId = null;

        //Get list of all Contracts tied to the given Serial
        List<Id> contractIds = new List<Id>();
        for(Assigned_Serial__c assignedSerial: assignedSerials) {
            contractIds.add(assignedSerial.Subscription__r.SBQQ__Contract__c);
            if (mainQuoteId == null) {
                if(assignedSerial.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c != null) {
                    mainContract = assignedSerial.Subscription__r.SBQQ__Contract__c;
                    mainQuoteId = assignedSerial.Subscription__r.SBQQ__Contract__r.SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c;
                }
            }
        }
        //temp solution for no quotes
        if(mainQuoteId == null) {
            return '';
        }

        System.debug('Retrieved contracts1: ' + contractIds);

        //Remove duplicate Ids
        Set<Id> uniqueContracts = new Set<Id>();
        uniqueContracts.addAll(contractIds);
        uniqueContracts.remove(null);
        contractIds.clear();
        contractIds.addAll(uniqueContracts);

        System.debug('Retrieved contracts2: ' + contractIds);

        //If more than 1 Contract, move all renewals to the first Contract
        if(uniqueContracts.size() > 1) {
            RenewSubscriptionHelper.mergeQuotes(mainContract, mainQuoteId, contractIds);
        }

        RenewSubscriptionHelper.deleteQuoteLines(mainQuoteId);

        Id currUserId = UserInfo.getUserId();

        //Get Quote
        SBQQ__Quote__c mainQuote = [
            SELECT
            Id,
            SBQQ__Account__c,
            SBCF_Reseller__c
            FROM SBQQ__Quote__c
            WHERE Id =: mainQuoteId
        ];

        Boolean ifEndUserAcctShareExists = AccountShareHelper.getAccountShare(mainQuote.SBQQ__Account__c, currUserId);

        if(ifEndUserAcctShareExists == false) {
            AccountShareHelper.addAccountShare(mainQuote.SBQQ__Account__c, currUserId);
        }
        if(mainQuote.SBCF_Reseller__c != null) {
            Boolean ifResellerAcctShareExists = AccountShareHelper.getAccountShare(mainQuote.SBCF_Reseller__c, currUserId);
            if(ifResellerAcctShareExists == false) {
                AccountShareHelper.addAccountShare(mainQuote.SBCF_Reseller__c, currUserId);
            }
        }

        //Return the Primary Quote of the renewal Opportunity of the First Expiring Contract
        return mainQuoteId;

    }

    @AuraEnabled
    public static void deleteQuoteLines(Id quoteId){

        //Retrieve existing quoteLines
        List<SBQQ__QuoteLine__c> quoteLines = [
            SELECT
            Id
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c = :quoteId
            AND (SBQQ__RenewedSubscription__r.Renewed_By_Subscription__c != null
            OR Is_Optional__c = true) 
            ];

        //Delete list of QuoteLines that have Subscriptions that are already renewed
        delete quoteLines;

    }

    @AuraEnabled
    public static void mergeQuotes(Id mainContract, Id mainQuoteId, List<String> uniqueContracts){
        Integer index = uniqueContracts.indexOf(mainContract);
        uniqueContracts.remove(index);

        //Get Quote
        SBQQ__Quote__c mainQuote = [
            SELECT
            Id,
            SBQQ__SubscriptionTerm__c,
            SBQQ__StartDate__c,
            SBQQ__EndDate__c
            FROM SBQQ__Quote__c
            WHERE Id =: mainQuoteId
        ];

        //Get the Subscriptions that need to be renewed
        List<SBQQ__Subscription__c> subscriptions = [
            SELECT
            Id,
            SBQQ__ProductName__c,
            SBQQ__Product__c,
            SBQQ__EndDate__c,
            SBQQ__Quantity__c,
            SBQQ__PricingMethod__c
            FROM SBQQ__Subscription__c
            WHERE SBQQ__Contract__c in :uniqueContracts
            AND Has_Been_Renewed__c = false
            AND SBQQ__Product__r.Lifecycle_Status__c != 'End of Life'
            ];

        //List of new QuoteLines to enter into DB
        List<SBQQ__QuoteLine__c> newQLs = new List<SBQQ__QuoteLine__c>();
        //Create QuoteLines for remaining Subscription
        for(SBQQ__Subscription__c sub: subscriptions) {
            Date startDate = sub.SBQQ__EndDate__c != null ? sub.SBQQ__EndDate__c.addDays(1) : mainQuote.SBQQ__StartDate__c;
            SBQQ__QuoteLine__c newQL = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = mainQuoteId,
                SBQQ__Product__c = sub.SBQQ__Product__c,
                SBQQ__StartDate__c = startDate,
                SBQQ__Quantity__c = sub.SBQQ__Quantity__c,
                SBQQ__PricingMethod__c = sub.SBQQ__PricingMethod__c,
                SBQQ__Renewal__c = true,
                SBQQ__RenewedSubscription__c = sub.Id
            );
            if(mainQuote.SBQQ__SubscriptionTerm__c != null) {
                newQL.SBQQ__SubscriptionTerm__c = mainQuote.SBQQ__SubscriptionTerm__c;
            } else {
                newQL.SBQQ__EndDate__c = mainQuote.SBQQ__EndDate__c;    
            }
            
            newQLs.add(newQL);
        }
        insert newQLs;

    }

    public static void makeQuoteAvailableOnPortal(String quoteId) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteId);
        quote.Available_on_Portal__c = true;

        update quote;
    }

    public class ContractQuoteIds {
		@AuraEnabled
		public String contractId {get; set;}

		@AuraEnabled
		public String quoteId {get; set;}
		
		public ContractQuoteIds(){}
	}
    
    @AuraEnabled
    public static Boolean callQuoteCalculator(Id quoteId){
        Boolean reCalculate = false;
        //Id loggedInUserId = UserInfo.getUserId();
        List<SBQQ__Quote__c> Quote = [SELECT Id, CreatedById FROM SBQQ__Quote__c WHERE Id =: quoteId LIMIT 1];
       if(Quote.size() > 0) { //&& Quote[0].CreatedById == loggedInUserId
            reCalculate = true;
            QuoteReader qr = new QuoteReader();
            QuoteModel quoteModel = qr.read(String.valueOf(quoteId));
            System.debug('quoteModel...'+JSON.serialize(quoteModel));
            QuoteCalculator calculator = new QuoteCalculator();
            calculator.calculate(quoteModel, 'QuoteCallback');
       }
        
        return reCalculate;
    }
    
    @AuraEnabled
    public static Boolean pollCalculatedQuote(String quoteId) {
        List<SBQQ__Quote__c> Quote = [SELECT Id, Quote_Calculated__c FROM SBQQ__Quote__c WHERE Id =: quoteId AND Quote_Calculated__c = true LIMIT 1];
        if(Quote.size() > 0) {
            return true;
        } else {
            return false;
        }
    }

}