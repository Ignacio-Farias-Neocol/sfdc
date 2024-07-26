import { LightningElement, track, api, wire } from 'lwc';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import refreshAmendmentsGetQuoteId from '@salesforce/apex/CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteId';
import cloneQuote from '@salesforce/apex/CPQ_RefreshAmendmentQuotes_Controller.cloneQuote';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['SBQQ__Quote__c.Name', 'SBQQ__Quote__c.SBQQ__StartDate__c', 'SBQQ__Quote__c.SBQQ__SubscriptionTerm__c', 'SBQQ__Quote__c.MSP_Net_Full_Amount__c'];

export default class refreshAmendmentQuotes extends LightningElement {
    @api recordId;

    @track inprogress;

    @track quoteId;
    @track gridColumns;
    @track gridData;

    @track quote;

    connectedCallback(){
        this.inprogress = true;
    }

    @wire(refreshAmendmentsGetQuoteId, { recordId: '$recordId' })
    wiredRefreshAmendmentsGetQuoteId({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error retrieving quote Id',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
        } else if (data) {
            this.quoteId = data.quoteId;
            this.gridColumns = data.amendmentOppties.columns;
            this.gridData = data.amendmentOppties.gridData;
        }
    }

    get hasAmendmentOppties() {
        return this.gridData && this.gridData.length > 0;
    }

    get hasNoAmendmentOppties() {
        return this.gridData && this.gridData.length == 0;
    }

    @wire(getRecord, { recordId: '$quoteId', fields: FIELDS}) 
    wiredRecord({ error, data }) {
        this.inprogress = false;
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading quote',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
        } else if (data) {
            this.quote = data;
        }
    }

    cloneClick(event) {
        //this.clickedButtonLabel = event.target.label;
        this.inprogress = true;

        let quoteId = this.quoteId;
        cloneQuote({quoteId : quoteId})
            .then(result => {
                this.inprogress = false;
                const closeQA = new CustomEvent('close');
                this.dispatchEvent(closeQA);
            })
            .catch(error => {
                this.inprogress = false;

                let message = 'Unknown error';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while starting replicate quote',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    }),
                );
            });
    }
}