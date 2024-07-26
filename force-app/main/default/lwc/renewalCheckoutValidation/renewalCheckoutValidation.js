import { LightningElement, wire} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import validateQuote from '@salesforce/apex/RenewalCheckoutHelper.renewalPreCheck';

export default class RenewalCheckoutValidation extends LightningElement {

    //Params from Url
    quoteId;

    isValid = false;
    validating = true;

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

    connectedCallback() {
        this.validate();
    }

    validate() {
        validateQuote({ quoteId: this.quoteId })
            .then((result) => {
                this.isValid = result;
                
                if(this.isValid) {
                    const navigateNextEvent = new FlowNavigationNextEvent();
                    this.dispatchEvent(navigateNextEvent);
                } else {
                    this.showToastErrorEvent();
                }   

                this.validating = false;
            })
            .catch((error) => {
                this.error = error;
                this.showToastErrorEvent();
                this.validating = false;
            });
    }

    showToastErrorEvent(){
        console.log('Error Toast');
        const event = new ShowToastEvent({
          title: 'Error',
          message: 'An error has occured when trying to validate the renewal. Please reach out to {0} and provide ' + this.quoteId + ' as reference.',
          messageData: [
            {
                url: 'community_help@barracuda.com',
                label: 'community_help@barracuda.com' 
            }
            ],
          variant: 'error',
          mode: 'sticky'
        });
        this.dispatchEvent(event);
      }
}