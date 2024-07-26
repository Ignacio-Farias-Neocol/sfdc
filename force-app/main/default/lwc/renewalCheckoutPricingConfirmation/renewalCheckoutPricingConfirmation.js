import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getQuoteLineDetails from '@salesforce/apex/RenewalCheckoutHelper.getQuoteLineDetails';

//import custom labels
import renewalCheckoutPricingConfirmation from '@salesforce/label/c.g_RenewalCheckout_PricingConfirmation_Header';
import modificationRequestModal from '@salesforce/label/c.g_RenewalCheckout_PricingConfirmation_ModificationRequestModal_Label';
import pricingConfirmation from '@salesforce/label/c.g_RenewalCheckout_PricingConfirmation';

export default class RenewalCheckoutPricingConfirmation extends LightningElement {

  //render booleans
  isDataLoaded = false;

  currentPageReference = null; 
  urlStateParameters = null;
  //Params from Url
  quoteId;

  //isReadOnly dictates if data is read only, indicates component is used in quote renewal checkout
  isReadOnly = true;
  //Wired Data
  quote;
  serials;
  serialSubs = {
    serialSubMap: {}
  };
  
  labels = {
    renewalCheckoutPricingConfirmation,
    modificationRequestModal,
    pricingConfirmation
  };

  //Retrieve quoteId param from url
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

  //Retrieve Quotelines sorted by serials from the url quoteId param
  @wire(getQuoteLineDetails, {
    quoteId: "$quoteId"
  })
  wiredSerials({error, data}) {
    console.log('QuoteId: ' + this.quoteId);
    console.log('retrieving data');
    if (data) {
      console.log('wiring serialSubs');
      this.serialSubs = data;
      if(data.quote) {
        this.quote = data.quote;
        this.accountId = this.quote.accountId;
      }
      console.log('serialSubs: ' + this.serialSubs);
      if (data.serials && data.serials.length > 0) {
        console.log('wiring serials')
        this.serials = data.serials;
        console.log('serials: ' + this.serials.length);
      }
    }
    if (error) {
      console.log(error);
    }
    this.isDataLoaded = true;
  }

  //Handler for 'showmodification' event
  handleShowModificationRequest(event) {
    //placeholder call
    console.log('in event handler');
    this.template.querySelector('c-modification-request-modal').showModalPopup(
      this.quote.SBQQ__Opportunity2__c,
      this.quote.SBQQ__Account__c,
      this.quote.SBQQ__Account__r.Name,
      this.quote.Name
    );
  }

  handlerequestcreated(event) {
    // After a 1.5 second delay, navigate the user back to the my products page
    setTimeout(function(){
      var navigationURL = window.location.origin + "/partners2/s/my-products";
      window.location.assign(navigationURL);
    }, 1.5*1000);
  }
}