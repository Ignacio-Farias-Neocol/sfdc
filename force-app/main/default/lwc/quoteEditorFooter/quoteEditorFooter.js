import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import approveQuote from "@salesforce/apex/QuoteEditorFooterHelper.approveQuote";

export default class QuoteEditorFooter extends NavigationMixin(LightningElement) {
    channelName = '/event/Portal_QLE_Save__e';
    subscription = {};

    quoteId;
    spinnerVisibility = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            this.setParametersBasedOnUrl();
        }
    }

    setParametersBasedOnUrl() {
        this.quoteId = this.urlStateParameters.recordId || null;
    }

    approveQuote() {
        approveQuote({quoteId: this.quoteId})
        .then(result => {
            console.log(result);
        })
        .catch(error => {
            console.log(error);
        });
    }


    handleNext() {
        this.spinnerVisibility = true;
        approveQuote({quoteId: this.quoteId})
            .then(result => {
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                    attributes: {
                        pageName: 'renewal-checkout'
                    },
                    state: {
                        quoteId: this.quoteId
                    }
                });
            })
            .catch(error => {
                this.spinnerVisibility = false;
                console.log(error);
            });
    }

    handlePrevious() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'my-products'
            }
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