public with sharing class QuoteDetailController {

    private SBQQ__Quote__c quote;
    private List<SBQQ__QuoteLine__c> quoteLines;

    public QuoteDetailController() {
        quote = [SELECT Id, Name, SBCF_Create_Date__c, 
                    SBCF_Expire_Date__c, 
                    SBCF_Doc_Start_Date__c, 
                    SBCF_Reseller_Bill_To_Name__c, 
                    SBCF_Partner_Level__c, 
                    End_User_Contact_Company__c, 
                    PrimaryContactName__c, 
                    SBQQ__NetAmount__c,
                    End_User_Contact_Street__c,
                    End_User_Contact_City__c,
                    End_User_Contact_State__c,
                    End_User_Contact_Zip__c,
                    End_User_Contact_Country__c,
                    //Changes done as a part of SFDC-18161: START
                    //Opp_Deal_Reg_Tracking_No__c,
                    SBCF_Deal_Reg_Tracking_No__c,
                    //Changes done as a part of SFDC-18161: START
                    SBCF_Renewal_Partner_of_Record__c,
                    Bill_To_Account_Name__c,
                    SBQQ__BillingName__c,
                    SBQQ__BillingStreet__c,
                    SBQQ__BillingCity__c,
                    SBQQ__BillingState__c,
                    SBQQ__BillingPostalCode__c,
                    SBQQ__BillingCountry__c,
                    SBQQ__ShippingName__c,
                    Ship_To_Contact_Name__c,
                    SBQQ__ShippingStreet__c,
                    SBQQ__ShippingCity__c,
                    SBQQ__ShippingState__c,
                    SBQQ__ShippingPostalCode__c,
                    SBQQ__ShippingCountry__c,
                    CurrencyIsoCode
                FROM SBQQ__Quote__c 
                WHERE Id = :ApexPages.currentPage().getParameters().get('id')];

        quoteLines = [SELECT Id, 
                        Document_Product_Code__c,
                        Doc_Product_Description__c,
                        Extended_Regular_Unit_Price__c,
                        SBCF_Document_Term__c,
                        Extended_List_Unit_Price__c,
                        SBQQ__Quantity__c,
                        Extended_Price__c,
                        SBCF_Document_Promo_Discount__c,
                        Price_After_Promo__c,
                        SBCF_Document_Discount__c,
                        Price_After_Additional_Disc__c,
                        Document_Disti_Partner_Disc__c,
                        Disti_Partner_Price__c,
                        Document_Total_List_Discount__c,
                        Final_Price2__c,
                        CurrencyIsoCode
                        FROM SBQQ__QuoteLine__c 
                        WHERE SBQQ__Quote__c = :ApexPages.currentPage().getParameters().get('id') AND SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c != 'Never'];
    }

    public SBQQ__Quote__c getQuote() {
        return quote;
    }

    public List<SBQQ__QuoteLine__c> getQuoteLines() {
        return quoteLines;
    }

    public String getEndUserString() {
        String endUserString = quote.End_User_Contact_Company__c;
        endUserString += '<br/>' + quote.PrimaryContactName__c;
        endUserString += '<br/>' + quote.End_User_Contact_Street__c;
        endUserString += '<br/>' + quote.End_User_Contact_City__c + ', '  + quote.End_User_Contact_State__c + ', ' + quote.End_User_Contact_Zip__c;
        endUserString += '<br/>' + quote.End_User_Contact_Country__c;

        return endUserString;
    }

    public String getBillToString() {
        String endUserString = quote.Bill_To_Account_Name__c;
        endUserString += '<br/>' + quote.SBQQ__BillingName__c;
        endUserString += '<br/>' + quote.SBQQ__BillingStreet__c;
        endUserString += '<br/>' + quote.SBQQ__BillingCity__c + ', '  + quote.SBQQ__BillingState__c + ', ' + quote.SBQQ__BillingPostalCode__c;
        endUserString += '<br/>' + quote.SBQQ__BillingCountry__c;

        return endUserString;
    }

    public String getShipToString() {
        String endUserString = quote.SBQQ__ShippingName__c;
        endUserString += '<br/>' + quote.Ship_To_Contact_Name__c;
        endUserString += '<br/>' + quote.SBQQ__ShippingStreet__c;
        endUserString += '<br/>' + quote.SBQQ__ShippingCity__c + ', '  + quote.SBQQ__ShippingState__c + ', ' + quote.SBQQ__ShippingPostalCode__c;
        endUserString += '<br/>' + quote.SBQQ__ShippingCountry__c;

        return endUserString;
    }
}