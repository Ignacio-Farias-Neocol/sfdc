import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/** renewSubscriptions() method in RenewSubscriptionHelper Apex class */
import renewSubscriptions from '@salesforce/apex/RenewSubscriptionHelper.renewSubscriptions';
import getRenewalQuote from '@salesforce/apex/RenewSubscriptionHelper.getRenewalQuote';
import pollRenewalQuote from '@salesforce/apex/RenewSubscriptionHelper.pollRenewalQuote';
import callQuoteCalculator from '@salesforce/apex/RenewSubscriptionHelper.callQuoteCalculator';
import pollCalculatedQuote from '@salesforce/apex/RenewSubscriptionHelper.pollCalculatedQuote';

//Import custom labels
import header from '@salesforce/label/c.g_SerialConfirmationModal_Header';
import text from '@salesforce/label/c.g_SerialConfirmationModal_Text';
import cancelButton from '@salesforce/label/c.g_SerialConfirmationModal_CancelButton';
import confirmButton from '@salesforce/label/c.g_SerialConfirmationModal_ConfirmButton';

const DELAY = 250;

export default class SerialConfirmationModal extends NavigationMixin(LightningElement) {

    @api
    confirmModal(requiresConfirmation, quoteId, serialId) {
        this.quoteId = quoteId;
        this.serialId = serialId;
        if(requiresConfirmation){
            this.showModal = requiresConfirmation;
        } else {
            this.navigateToRenewal();
        }
    }

    //Custom Labels
    label = {
        header,
        text,
        cancelButton,
        confirmButton
    }

    //Determines if the modal is visible
    showModal = false;

    //Tracks the quoteID of the serial to send to QLE
    quoteId;
    contractId;
    serialId;
    spinnerVisibility = false;

    count = 0;
    pollCalculateQuotecount = 0;

    spinnerText = 'Generating renewal. This process may take some time.';

    hideModal() {
        this.showModal = false;
    }

    navigateToRenewal() {
        this.hideModal();
        this.spinnerVisibility = true;
        getRenewalQuote({serialId: this.serialId}).then(result => {
            this.contractId = result.contractId;
            this.quoteId = result.quoteId;
            if(this.quoteId == undefined || this.quoteId == null || this.quoteId == '') {
                this.count = 0;
                this.pollRenewalQuote();
            } else {
                this.renewSubscriptions();
            }
        })
        .catch(error => {
            console.log('error...' + JSON.stringify(error));
            this.showToastErrorEvent();
        });
    }

    renewSubscriptions() {
        renewSubscriptions({serialId: this.serialId}).then(result => {
            console.log('DEBUG... serialId: ' + this.serialId);
            console.log('Renewed Subscriptions');
            this.quoteId = result;
            if(this.quoteId == undefined || this.quoteId == null || this.quoteId == '') {
                console.log('No quote found');
                this.showToastErrorEvent();
                return;
            }
            else{
				console.log('QuoteId'+this.quoteId);
                callQuoteCalculator({quoteId: this.quoteId}).then(result => {
                    console.log('callQuoteCalculator...'+result);
                    if(result){
                        this.pollCalculateQuotecount = 0;
                        this.pollCalculateQuote();
                    }
                    else{ 
						console.log('Navigate to Quote');                       
                        this.naviagateToQuote();
                    }
                })
            }
        })
        .catch(error => {
            console.log('error...' + JSON.stringify(error));
                    this.showToastErrorEvent();
        });
    }

    naviagateToQuote(){
        this.spinnerVisibility = false;
        //redirect to QLE
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',            
            attributes: {
                pageName: 'quote-editor'
            },
            state: {
                recordId: this.quoteId
            }
        });
    }

    pollCalculateQuote() {
        this.pollCalculateQuotecount += 1;
        if( this.pollCalculateQuotecount > 2400) {
            console.log('pollCalculateQuote timeout)');
            this.showToastErrorEvent();
            return;
        }
        pollCalculatedQuote({quoteId: this.quoteId}).then(result => {
            console.log('Result from poll: ' + result);
            //Inconclusive status. Continue polling
            if(!result) {
                clearTimeout(this.delayTimeout);
                this.delayTimeout = setTimeout(() => {
                this, this.pollCalculateQuote();
                }, DELAY);
            } else {
                this.naviagateToQuote();
            }
        })
        .catch(error => {
            console.log('error...' + JSON.stringify(error));
            this.showToastErrorEvent();
        });
    }

    pollRenewalQuote() {
        this.count += 1;
        if( this.count > 2400) {
            console.log('timeout)');
            this.showToastErrorEvent();
            return;
        }
        pollRenewalQuote({contractId: this.contractId}).then(result => {
            this.quoteId = result;
            console.log('Result from poll: ' + result);
            //Inconclusive status. Continue polling
      if(this.quoteId == undefined || this.quoteId == null || this.quoteId == '') {
                clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
          this, this.pollRenewalQuote();
        }, DELAY);
      } else {
                this.renewSubscriptions();
      }
    })
    .catch(error => {
        console.log('error...' + JSON.stringify(error));
                this.showToastErrorEvent();
    });
    }

    showToastErrorEvent(){
    console.log('Error Toast');
        this.spinnerVisibility = false;
    const event = new ShowToastEvent({
      title: 'Error',
      message: 'An error has occured when renewing your subscriptions. Please reach out to {0}',
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