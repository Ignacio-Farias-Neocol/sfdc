/** 
 * This controller is used in custom Quote template content
 * for the MSP Agreement in Salesforce CPQ
 * 
 * @author Micah Gerger
 * @date 2018/1/15
 * 
 *  SFDC-9274 Rewrite the code.
 *  SFDC-9873 switch displayed fields to Billing Aggregator fields.
 *  SFDC-10622 In the Existing Subscription section of the Contract, only show header of bundle
 *  SFDC-13204 Ensure that old renewed subscriptions are not considered for calc or display
 *  SFDC-13247 Ensure that subscriptions with expired contracts are not considered for calc or display
 *  SFDC-15135 MMC New Estimated Monthly Cost Fix
 */
public class AgreementViewController {
    public List<ShowSubsWrapper> subsWrapper {get; private set;}
    protected SBQQ__Quote__c quote;

    public Decimal monthlyAcctSum {get; set;}
    public Decimal quoteMonthlyTotal {get; set;}
    public Decimal newMonthlyTotal {get; set;}

    public String newMonthlyTotalStr {get; set;}
    public String monthlyAcctSumStr {get; set;}
    public String quoteCurrency {get; set;}

    public AgreementViewController() {}

    public PageReference init() {
        subsWrapper = new List<ShowSubsWrapper>();
        
        try {
            List<SBQQ__Quote__c> quotes = [SELECT Id, MSP_Doc_Monthly_Cost_Total__c, Existing_Monthly_Subs_Cost__c, SBQQ__Account__c, CurrencyISOCode, DocumentCurrencySymbol__c 
                                            FROM SBQQ__Quote__c 
                                            WHERE Id =: ApexPages.currentPage().getParameters().get('qid') and 
                                                SBQQ__Account__c <> NULL];
            if (quotes.size() == 0)
                return null;

            quote = quotes[0];
            quoteMonthlyTotal = quote.MSP_Doc_Monthly_Cost_Total__c; //Price Rule: MSP Pricing Totals Calculations
            quoteCurrency = quote.CurrencyISOCode;

            system.debug('The monthly total in this quote is '+ quoteMonthlyTotal);

            monthlyAcctSum = 0;
            List<SBQQ__Subscription__c > subs = [SELECT ID, Name, Product_Code__c,
                                                SBQQ__ProductName__c, 
                                                SBQQ__Quantity__c, 
                                                OverageRate__c, 
                                                SBQQ__StartDate__c,
                                                Monthly_Unit_Price__c, 
                                                ExtendedMonthlyPrice__c, //twined from quote line; New_Monthly_Total__c * SBQQ__EffectiveQuantity__c
                                                SBQQ__EndDate__c, 
                                                SBQQ__ListPrice__c, 
                                                SBCF_Serial_Number__c,
                                                SBQQ__RequiredById__c ,
                                                SBQQ__RevisedSubscription__c,
                                                SBQQ__RevisedSubscription__r.SBQQ__Quantity__c,
                                                SBQQ__RevisedSubscription__r.ExtendedMonthlyPrice__c,
                                                SBQQ__QuoteLine__c,
                                                SBQQ__Contract__r.EndDate,
                                                SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c,
                                                SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c,
                                                SBQQ__TerminatedDate__c,
                                                CurrencyISOCode,
                                                SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c
                                            FROM SBQQ__Subscription__c
                                            WHERE Business_Group__c = 'MSP' AND 
                                                SBQQ__Account__c =: quote.SBQQ__Account__c AND
                                                Renewed_By_Subscription__c = null AND //SFDC-13204. Ensure that old renewed subscriptions are not considered for calc or display
                                                SBQQ__Contract__r.EndDate >= TODAY AND //SFDC-13247. Ensure subscriptions with expired contracts are not considered for calc or display
                                                (SBQQ__TerminatedDate__c = NULL or SBQQ__TerminatedDate__c > TODAY)
                                            Order By SBQQ__RevisedSubscription__c NULLS FIRST];
            Set<String> renewedSubIds = new Set<String>();
            
             Set<String> SLMMCIds = new Set<String>(); // SFDC-15135
            for(SBQQ__Subscription__c sub : subs) {
            
            if(sub.Product_Code__c=='SL-MMC' )
               SLMMCIds.add(sub.Id);
            }
            
            for(SBQQ__Subscription__c sub : subs) {
                //subs have been renewed will be excluded from the calculation and displayed list
                if (!String.isEmpty(sub.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c)) {
                    renewedSubIds.add(sub.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c);
                }
                //subs revised by subs have been renewed also will be excluded from the calculation and displayed list - this is will never happen
                if (!String.isEmpty(sub.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c)) {
                    renewedSubIds.add(sub.SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c);
                }
            }

            //collect mastersubs and revised quantity and price 
            Map<String, SBQQ__Subscription__c> masterSubs = new Map<String, SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub : subs) {
                //exclude renewed subs
                if (renewedSubIds.contains(sub.Id))
                    continue;
                
                //collect master sub, +/- quantity and price of subs that revised the the master
                if (String.isEmpty(sub.SBQQ__RevisedSubscription__c)) {
                    masterSubs.put(sub.Id, sub);
                } else {
                    SBQQ__Subscription__c master = masterSubs.get(sub.SBQQ__RevisedSubscription__c);
                    System.debug('*** master ' + master);
                    System.debug('*** sub ' + sub);

                    if (master != null) {
                        master.SBQQ__Quantity__c = (master.SBQQ__Quantity__c != null ? master.SBQQ__Quantity__c : 0) + (sub.SBQQ__Quantity__c == null ? 0 :  sub.SBQQ__Quantity__c);

                        master.ExtendedMonthlyPrice__c = (master.ExtendedMonthlyPrice__c != null ? master.ExtendedMonthlyPrice__c : 0) + (sub.ExtendedMonthlyPrice__c == null ? 0 : sub.ExtendedMonthlyPrice__c);
                    }
                    System.debug('*** master 2 ' + master);
                }
            }

            String currencyISOCodeToUse = quoteCurrency;
            for(SBQQ__Subscription__c sub : masterSubs.values()) {
                currencyISOCodeToUse = sub.CurrencyISOCode;
            }

            //add master to the list to be displayed in quote doc
            //sum up total revised monthly price of the master
            for(SBQQ__Subscription__c sub : masterSubs.values()) {
            
               if(!String.isEmpty(sub.SBQQ__RequiredById__c) && SLMMCIds.contains(sub.SBQQ__RequiredById__c)) // SFDC-15135
               continue;
               
                System.debug('*** sub ' + sub);
                //SFDC-10622
                /*if (sub.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c == NULL||
                        (sub.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c != 'Editor Only' && 
                        sub.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c != 'Never')) {*/
                //SFDC-13247: Expired contract check from this if condition
                //This check is happening in query to fetch subscriptions
                if ((sub.SBQQ__TerminatedDate__c == NULL || sub.SBQQ__TerminatedDate__c > Date.TODAY()) && 
                    sub.SBQQ__RevisedSubscription__c == null &&
                    sub.SBQQ__RequiredById__c == NULL &&
                    sub.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c != 'Editor Only' &&
                    sub.SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c != 'Never') {
                    subsWrapper.add(new ShowSubsWrapper(sub));
                    System.Debug(sub);
                }
                
                monthlyAcctSum = monthlyAcctSum + (sub.ExtendedMonthlyPrice__c == null ? 0 : sub.ExtendedMonthlyPrice__c);
            }
            System.debug('Total Existing Monthly Subscription Cost = ' + monthlyAcctSum);

            subsWrapper.sort();

            if (quote.Existing_Monthly_Subs_Cost__c != monthlyAcctSum) {
                quote.Existing_Monthly_Subs_Cost__c = monthlyAcctSum;
                update quote;
            }

            newMonthlyTotal = monthlyAcctSum + quoteMonthlyTotal;
            System.debug('New Monthly Total = ' + newMonthlyTotal);

            newMonthlyTotalStr = currencyISOCodeToUse + ' ' + formatDecimal(newMonthlyTotal, 2, true);
            monthlyAcctSumStr = currencyISOCodeToUse + ' ' + formatDecimal(monthlyAcctSum, 2, true);
        } catch (Exception exc) { // error if there is an issue getting subscriptions
            String errorMsg = 'There was an error getting Subscriptions for our Quote. Exception Cause = ' + exc.getCause() + ', Exception Message = ' + exc.getMessage();
            System.debug('=====> ' + errorMsg);
            System.debug(exc.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
        }
        
        return null;
    }

    // wrapper to collect subscriptions and values to present on document
    public class ShowSubsWrapper implements Comparable {
        public String name {get; set;}
        public Decimal unitPrice {get; set;}
        public Decimal quantity {get; set;}
        public Decimal monthlyUnitPrice {get; set;}        
        public Decimal overageRate {get; set;}
        public date startDate {get; set;}
        public String productName {get; set;}
        public String serialNo {get; set;}

        public String unitPriceStr {get; set;}
        public String overageRateStr {get; set;}
        public String monthlyUnitPriceStr {get; set;}

        public ShowSubsWrapper(SBQQ__Subscription__c sub) {
            this.name = sub.Name;
            this.unitPrice = sub.ExtendedMonthlyPrice__c;
            this.quantity = sub.SBQQ__Quantity__c;
            this.monthlyUnitPrice = sub.Monthly_Unit_Price__c;
            this.overageRate = sub.OverageRate__c == null ? 0 : sub.OverageRate__c.setScale(2);
            this.startDate = sub.SBQQ__StartDate__c;
            this.productName = sub.SBQQ__ProductName__c == null ? '' : sub.SBQQ__ProductName__c.replaceAll('&', '&amp;').replaceAll('>', '&gt;').replaceAll('<', '&lt;').replaceAll('\'', '&apos;').replaceAll('"', '&quot;');//SFDC-11711: escape special chars 
            this.serialNo = '';
            if (sub.SBCF_Serial_Number__c != null) {
                List<String> serialNos = new List<String>();
                for (String s : sub.SBCF_Serial_Number__c.split(',')) {
                    if (!String.isEmpty(s)) {
                        serialNos.add(s);
                    }
                }

                if (serialNos.size() == 1) {
                    this.serialNo = serialNos[0]; // ensure that there is space
                }
            }

            String docCurrencySymbol = codeToSymbol(sub.CurrencyISOCode);
            String currencySymbol = docCurrencySymbol.length() >= 3 ? docCurrencySymbol + ' ' : docCurrencySymbol;
            this.unitPriceStr = currencySymbol + formatDecimal(unitPrice, 2, true);
            this.monthlyUnitPriceStr = currencySymbol + formatDecimal(monthlyUnitPrice, 2, true);
            this.overageRateStr = currencySymbol + formatDecimal(overageRate, 2, true);
        }

        public Integer compareTo(Object compareTo) {
            ShowSubsWrapper compareToSW = (ShowSubsWrapper)compareTo;
            try {
                if (name == compareToSW.name) return 0;
                if (name > compareToSW.name) return 1;
                return -1;
            } catch (Exception e) {
                return 0;
            }
        }
    }

    @TestVisible
    private static String formatDecimal(Decimal d, Integer decimals, Boolean treatBlankZero) {
        if (d == null) {
            if (treatBlankZero == true)
                return '0.' + '0'.repeat(decimals);
            return null;
        }

        //1234.90
        Decimal d2 = d.setScale(decimals);
        //1234.9
        String d2str = d2.format();

        String d2d = d2str.substringAfterLast('.'); //9
        String d2i = d2str.substringBeforeLast('.');//1234
        if (String.isEmpty(d2d)) {
            return d2i + '.' + '0'.repeat(decimals);
        }

        return d2i + '.' + d2d.rightPad(decimals, '0');//1234.90
    }

    @TestVisible
    private static String codeToSymbol(String currencyISOCode) {
        if (String.isEmpty(currencyISOCode))
            return '$';
        
        switch on currencyISOCode {
            when 'EUR' {return '€';}
            when 'GBP' {return '£';}
            when 'USD' {return '$';}
            when 'JPY' {return '¥';}
            when 'RMB' {return '¥';}
            when 'CHF' {return 'CHF';}
            when else {return currencyISOCode;}
        }
    }
}
/*
Integer i = 0;
for (SBQQ__QuoteLine__c ql : [SELECT ID, SBCF_Serial_Number__c, SBQQ__Product__c, SBQQ__Product__r.Name, SBQQ__Product__r.Family From SBQQ__QuoteLine__c Where SBQQ__Quote__r.Business_Group__c = 'MSP']) {
    if (ql.SBCF_Serial_Number__c != null && ql.SBCF_Serial_Number__c.indexOf(',') > 0) {
        i++;
        System.Debug('*** ql ' + ql.ID + ', ' + ql.SBQQ__Product__c + ', ' + ql.SBQQ__Product__r.Family + ', ' + ql.SBQQ__Product__r.Name + ', ' + ql.SBCF_Serial_Number__c);
        
        if (i == 100) {
            break;
        }
    }
}
 */