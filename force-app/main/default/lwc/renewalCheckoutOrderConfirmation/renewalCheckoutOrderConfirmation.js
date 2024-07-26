import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getQuoteLineDetails from '@salesforce/apex/RenewalCheckoutHelper.getQuoteLineDetails';
// import getQuoteOrder from '@salesforce/apex/RenewalCheckoutHelper.getQuoteOrder';

//import custom labels
import orderConfirmationInfoText from '@salesforce/label/c.g_RenewalCheckout_OrderConfirmation_InformationText';
import paymentInformation from '@salesforce/label/c.g_RenewalCheckout_PaymentInformation';
import emailConfirmation from '@salesforce/label/c.g_RenewalCheckout_OrderConfirmation_EmailConfirmation';
import creditCard from '@salesforce/label/c.g_RenewalCheckout_CreditCard';
import shippingAddress from '@salesforce/label/c.g_RenewalCheckout_ShippingAddress';
import billingAddress from '@salesforce/label/c.g_RenewalCheckout_BillingAddress';
import poNumber from '@salesforce/label/c.g_RenewalCheckout_PurchaseOrderNumber';
import ccInfo from '@salesforce/label/c.g_RenewalCheckout_CreditCardInfo';
import ccDigits from '@salesforce/label/c.g_RenewalCheckout_CreditCard_Last4Digits';
import ccType from '@salesforce/label/c.g_RenewalCheckout_CreditCard_Type';
import ccExpDate from '@salesforce/label/c.g_RenewalCheckout_CreditCard_ExpirationDate';

export default class RenewalCheckoutOrderConfirmation extends LightningElement {
  //render booleans
  isDataLoaded = false;

  //Params from Url
  currentPageReference = null; 
  urlStateParameters = null;

  //isReadOnly dictates if data is read only, indicates component is used in quote renewal checkout
  isReadOnly = true;

  //Id of the selected credit card
  @api selectedCreditCard;

  @api poNumber;
  //Wired Data
  serials;
  serialSubs = {
    serialSubMap: {}
  };
  quote = {
    Name: ""
  };
  orderNumber = '';

  labels = {
    orderConfirmationInfoText,
    paymentInformation,
    emailConfirmation,
    creditCard,
    shippingAddress,
    billingAddress,
    // street,
    // city,
    // state,
    // zipCode,
    // country,
    poNumber,
    ccInfo,
    ccDigits,
    ccType,
    ccExpDate
  }
  
  @api ccDigits;
  @api ccType;
  @api ccExpDate;
  @api shippingAccountName;
  @api shippingStreet;
  @api shippingState;
  @api shippingCity;
  @api shippingZipCode;
  @api shippingCountry;
  @api billingAccountName;
  @api billingAccountEmail;
  @api billingStreet;
  @api billingState;
  @api billingCity;
  @api billingZipCode;
  @api billingCountry;

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

  //getQuoteLineDetails
  @wire(getQuoteLineDetails, {
    quoteId: "$quoteId"
  })
  wiredSerials({error, data}) {
    console.log('Wired quoteLineDetails');
    if (data) {
      this.serialSubs = data;
      if(data.quote) {
        this.quote = data.quote;
        this.accountId = this.quote.accountId;
      }
      if (data.serials && data.serials.length > 0) {
        this.serials = data.serials;
      }
    }
    if (error) {
      console.log(error);
    }
    this.isDataLoaded = true;
  }

  // @wire(getQuoteOrder, {
  //   quoteId: "quoteId"
  // })
  // wiredQuote({error, data}) {
  //   console.log('Wired quoteOrder');
  //   if (data) {
  //     this.orderNumber = data;
  //   }
  //   if (error) {
  //     console.log(error);
  //     // console.log('error...' + JSON.stringify(error));
  //   }
  // }
}