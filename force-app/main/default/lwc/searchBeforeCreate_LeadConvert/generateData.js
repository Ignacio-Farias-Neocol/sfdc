export default function generateData({ amountOfRecords }) {
    return [...Array(amountOfRecords)].map((_, index) => {
        return {
            Id: `${index}`,
            Name: `Customer (${index})`,
            Website: 'google.com',
            Alternative_Account_Name__c:'Alternate',
            Type: 'Customer',
            BusinessGroup__c:'Core',
            BillingCountry: 'US',
            BillingCity:'Campbell',
            ARR__c:'ARR',   
            CurrencyIsoCode: 'USD'
        };
    });
}