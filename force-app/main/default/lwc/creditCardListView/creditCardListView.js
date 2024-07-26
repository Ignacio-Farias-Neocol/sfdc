import { LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from "@salesforce/user/Id";

import getCreditCards from "@salesforce/apex/CreditCardListViewHelper.getCreditCards";

//Import Custom Labels
import addressHeader from '@salesforce/label/c.g_RenewalCheckout_BillingAddress';
import ccDigits from '@salesforce/label/c.g_RenewalCheckout_CreditCard_Last4Digits';
import ccType from '@salesforce/label/c.g_RenewalCheckout_CreditCard_Type';
import ccExpDate from '@salesforce/label/c.g_RenewalCheckout_CreditCard_ExpirationDate';
import billingAddress from '@salesforce/label/c.g_RenewalCheckout_BillingAddress';
import creditCardsHeader from '@salesforce/label/c.g_PaymentMethods_CreditCards';
import addCreditCard from '@salesforce/label/c.g_PaymentMethods_AddCreditCard';

import userContactAccountId from '@salesforce/schema/User.Contact.AccountId';

const columns = [
  {
    type: "text",
    fieldName: "type",
    label: ccType,
    wrapText: false,
    sortable: false
  },
  {
    type: "text",
    fieldName: "last4OfCC",
    label: ccDigits,
    wrapText: false,
    sortable: false
  },
  {
    type: "text",
    fieldName: "expiration",
    label: ccExpDate,
    wrapText: false,
    sortable: false
  }
]

export default class CreditCardListView extends LightningElement {

  userId = Id;
  
  ccData;
  address = {
    street: '',
    city: '',
    state: '',
    zip: '',
    country: ''
  };

  labels = {
    addressHeader,
    billingAddress,
    creditCardsHeader,
    addCreditCard
  }
  columns = columns;

  @wire(getRecord, { recordId: Id, fields: [userContactAccountId]}) 
  userDetail;

  @wire(getCreditCards, {
    userId: "$userId"
  })
  wiredCC({error, data}) {
    if(data){
      this.ccData = data.creditCards;
      this.address = data.address;
    }  else if (error) {
      console.log('error : ' + JSON.stringify(error));
    }
  }

  get accountId() {
    return getFieldValue(this.userDetail.data, userContactAccountId);
  }
  
  addCreditCard(){
    console.log('inside addCreditCard...');
    console.log('inside addCreditCard account Id...'+this.accountId);
    //this.template.querySelector('c-credit-card-entry-l-w-c').getURL();
    this.template.querySelector('c-credit-card-entry-l-w-c').getURLwithKey(this.accountId);
    //window.open('https://www.barracuda.com/new_portal/addCard?aid=001f200001zWCijAAG');
  }

}