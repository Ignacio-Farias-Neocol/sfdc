import { api,wire, LightningElement } from 'lwc';
import GetCreditCardURL from '@salesforce/apex/WebIntegrationController.getCreditCardURL';
import GetCreditCardURLwithKey  from '@salesforce/apex/WebIntegrationController.getCreditCardURLwithKey';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CreditCardEntryLWC extends LightningElement {

    @api
    recordId;

    status = false;

    @api
    getURL() {
        GetCreditCardURL({recordId: this.recordId})
            .then(result => {
                if(result.status == 'SUCCESS') {
                    let url = result.url;
                    window.open(url);
                } else {
                    const evt = new ShowToastEvent({
                        message: result.failure_message,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            })
            .catch(error => {
                console.log('In error');
                console.log(error);
                const evt = new ShowToastEvent({
                    message: 'Encountered an error trying to add a credit card. Please reach out to ',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
    }

    @api
    getURLwithKey(accId) {
        console.log('inside getURLwithKey...'+accId);
        GetCreditCardURLwithKey({recordId: accId})
            .then(result => {
                if(result.status == 'SUCCESS') {
                    let url = result.url;
                    console.log('URLwithKey...'+url);
                    window.open(url);                    
                } else {
                    console.log('error ...'+JSON.stringify(result));
                    const evt = new ShowToastEvent({
                        message: result.failure_message,
                        variant: 'error',
                    });
                    this.dispatchEvent(evt);
                }
            })
            .catch(error => {
                console.log('In error');
                console.log(error);
                const evt = new ShowToastEvent({
                    message: 'Encountered an error trying to add a credit card. Please reach out to ',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });
    }
}