import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
  FlowNavigationBackEvent,
  FlowNavigationNextEvent
} from 'lightning/flowSupport';

import getQuoteLineDetails from '@salesforce/apex/RenewalCheckoutHelper.getQuoteLineDetails';
import getAddresses from '@salesforce/apex/RenewalCheckoutHelper.getBillingShippingAddresses';
import processOrder from '@salesforce/apex/RenewalCheckoutHelper.processOrder';
import pollJob from '@salesforce/apex/RenewalCheckoutHelper.pollJob';

//Import getRecord
import { getRecord } from 'lightning/uiRecordApi';
import LAST4OFCC_FIELD from '@salesforce/schema/Credit_Card__c.Last_4_of_CC__c';
import CCTYPE_FIELD from '@salesforce/schema/Credit_Card__c.Card_Type__c';
import CCEXPIRYDATE_FIELD from '@salesforce/schema/Credit_Card__c.Expiration__c';

//import custom labels
import orderReviewHeader from '@salesforce/label/c.g_RenewalCheckout_OrderReview_Header';
import paymentInformation from '@salesforce/label/c.g_RenewalCheckout_PaymentInformation';
import creditCardHeader from '@salesforce/label/c.g_RenewalCheckout_CreditCard';
import shippingAddress from '@salesforce/label/c.g_RenewalCheckout_ShippingAddress';
import billingAddress from '@salesforce/label/c.g_RenewalCheckout_BillingAddress';
import poNumber from '@salesforce/label/c.g_RenewalCheckout_PurchaseOrderNumber';
import ccInfo from '@salesforce/label/c.g_RenewalCheckout_CreditCardInfo';
import ccDigits from '@salesforce/label/c.g_RenewalCheckout_CreditCard_Last4Digits';
import ccType from '@salesforce/label/c.g_RenewalCheckout_CreditCard_Type';
import ccExpDate from '@salesforce/label/c.g_RenewalCheckout_CreditCard_ExpirationDate';

//const for time delay when polling job status
const DELAY = 250;

export default class RenewalCheckoutOrderReview extends LightningElement {

  //Id of the selected credit card
  @api selectedCreditCard;

  @api poNumber;

  labels = {
    orderReviewHeader,
    paymentInformation,
    creditCardHeader,
    shippingAddress,
    billingAddress,
    poNumber,
    ccInfo,
    ccDigits,
    ccType,
    ccExpDate
  };

  spinnerVisibility = false;

  currentPageReference = null; 
  urlStateParameters = null;
  
  //Params from Url
  quoteId;
  isDataLoaded = false;
  isReadOnly = true;

  //Serial Data
  serials;
  serialSubs = {
    serialSubMap: {}
  };
  
  selectedCCRecord;
  cardDetails;
  @api autoRenew;
  @api ccType = '';
  @api ccExpDate = '';
  @api ccDigits = '';
  @api shippingAccountName = '';
  @api shippingStreet = '';
  @api shippingState = '';
  @api shippingCity = '';
  @api shippingZipCode = '';
  @api shippingCountry = '';
  @api billingAccountName = '';
  @api billingAccountEmail = '';
  @api billingStreet = '';
  @api billingState = '';
  @api billingCity = '';
  @api billingZipCode = '';
  @api billingCountry = '';
  @api orderId = '';
  shippingAddressString = '';
  billingAddressString = '';
  jobId;

  //AsyncApexJobId

  //Flow Navigation Vars
  @api availableActions = [];

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
     if (currentPageReference) {
        this.urlStateParameters = currentPageReference.state;
        this.setParametersBasedOnUrl();
     }
  }

  setParametersBasedOnUrl() {
    this.quoteId = this.urlStateParameters.quoteId || null;
  }

  @wire(getAddresses, {
    quoteId: "$quoteId"
  })
  wiredAddresses({error, data}) {
    console.log('wired addresses');
    if(data) {
      console.log('Address data: ' + JSON.stringify(data));
      this.ShippingAccountName = data.Shipping_Address__r?.Account__r?.Name;
      this.shippingStreet = data.Shipping_Address__r?.Street__c;
      this.shippingState = data.Shipping_Address__r?.State__r?.Name;
      this.shippingCity = data.Shipping_Address__r?.City__c,
      this.shippingZipCode = data.Shipping_Address__r?.Zip_Postal_Code__c;
      this.shippingCountry = data.Shipping_Address__r?.Country__r?.Name;
      this.billingAccountName = data.Billing_Address__r?.Account__r.Name;
      this.billingAccountEmail = data.Billing_Address__r?.Account__r?.Bill_To_Email__c;
      this.billingStreet = data.Billing_Address__r?.Street__c;
      this.billingState = data.Billing_Address__r?.State__r?.Name;
      this.billingCity = data.Billing_Address__r?.City__c,
      this.billingZipCode = data.Billing_Address__r?.Zip_Postal_Code__c;
      this.billingCountry = data.Billing_Address__r?.Country__r?.Name;

      let billingAddressStringList = [this.billingCity, this.billingState, this.billingZipCode, this.billingCountry];
      let shippingAddressStringList = [this.shippingCity, this.shippingState, this.shippingZipCode, this.shippingCountry];
      billingAddressStringList = billingAddressStringList.filter(element => element != undefined);
      shippingAddressStringList = shippingAddressStringList.filter(element => element != undefined);
      this.billingAddressString = billingAddressStringList.join(', ');
      this.shippingAddressString = shippingAddressStringList.join(', ');

    }
    if(error) {
      console.log('error...' + JSON.stringify(error));
    }
  }

  @wire(getQuoteLineDetails, {
    quoteId: "$quoteId"
  })
  wiredSerials({error, data}) {
    console.log('wired quoteLineDetails');
    if (data) {
      this.serialSubs = data;
      if (data.serials && data.serials.length > 0) {
        this.serials = data.serials;
      }
    }
    if (error) {
      console.log('error...' + JSON.stringify(error));
    }
    this.isDataLoaded = true;
  }

  @wire(getRecord, {
    recordId: '$selectedCreditCard',
    fields: [LAST4OFCC_FIELD, CCTYPE_FIELD, CCEXPIRYDATE_FIELD]
  })
  wiredCreditCard({error, data}) {
    console.log('wired credit card');
    if(data) {
      this.selectedCCRecord = data;
      this.ccDigits = this.selectedCCRecord.fields.Last_4_of_CC__c.value;
      this.cardDetails = this.selectedCCRecord.fields.Card_Type__c.value;
      this.cardDetails += ' ending in ' + this.selectedCCRecord.fields.Last_4_of_CC__c.value;
      this.cardDetails += ', Exp: ' + this.selectedCCRecord.fields.Expiration__c.value;
    }
    if(error) {
      console.log('error...' + JSON.stringify(error));
    }
  }

  //Additional Functions for SFDC-17142
  /*
    handlePrevious
    processOrder
    pollForJobStatus
  */
  //Navigate to Previous Page in Flow
  handlePrevious(){
    // check if BACK is allowed on this screen
    if (this.availableActions.find((action) => action === 'BACK')) {
      // navigate to the next screen
      const navigateBackEvent = new FlowNavigationBackEvent();
      this.dispatchEvent(navigateBackEvent);
    }
  }

  handleNext(){
    // check if Next is allowed on this screen
    this.spinnerVisibility = false;
    if (this.availableActions.find((action) => action === 'NEXT')) {
      // navigate to the next screen
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    }
  }

  processOrder(){
    console.log('processing order');
    processOrder({
      quoteId: this.quoteId, 
      selectedCreditCard: this.selectedCreditCard, 
      poNumber: this.poNumber,
      autoRenew: this.autoRenew
    }).then(result => {
      this.jobId = result;
      console.log('JobId: ' + this.jobId);
      //Poll for Job completion to show user Order Confirmation
      this.spinnerVisibility = true;
      this.pollForJobStatus();
    })
    .catch(error => {
        this.showToastErrorEvent();
        console.log('error...' + JSON.stringify(error));
    });
  }

  counter = 0;

  pollForJobStatus(){
    console.log('Polling for Job. Counter: ' + this.counter);
    console.log('Polling for Job. JobId: ' + this.jobId);
    this.counter += 1;
    let status;

    //time limit of 1 minute
    if(this.counter > 240) {
      this.showToastErrorEvent();
      return;
    } 

    pollJob({jobId: this.jobId}).then(result => {
      status = result;
      console.log('Result is: ' + status);
      if (status === 'Success') {
        //Progress to next page
        this.handleNext();
      } else if (status === 'Failed') {
        //Toast notification for failure
        this.showToastErrorEvent();
      //Inconclusive status. Continue polling
      } else {
        clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
          this, this.pollForJobStatus();
        }, DELAY);
      }
    })
    .catch(error => {
      console.log('error...' + JSON.stringify(error));
      this.showToastErrorEvent();
    });
  }

  showToastErrorEvent(){
    console.log('Error Toast');
    const event = new ShowToastEvent({
      title: 'Error',
      message: 'An error has occured when submitting your order. Please reach out to {0}',
      messageData: [
        {
          url: 'community_help@barracuda.com',
          label: 'community_help@barracuda.com' 
        }
        ],
      variant: 'error'
    });
    this.dispatchEvent(event);
  }
}