/**
 * JS file to Upsell Renewal Oppty Creation
 * Update: SFDC-14110 - Flow for Upsell Button / Widget on Contract Record
 */

import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initiateUpsell from '@salesforce/apex/UpsellGuidanceController.initiateUpsell';
import { getRecord ,getFieldValue ,getRecordNotifyChange} from 'lightning/uiRecordApi';
import RENEWAL_OPPTY from '@salesforce/schema/Contract.SBQQ__RenewalOpportunity__c';
import { RefreshEvent } from 'lightning/refresh';

// Importing Custom Labels for Widget verbiage/button label
import UG_Amend from '@salesforce/label/c.UG_Amend';
import UG_Renew from '@salesforce/label/c.UG_Renew';
import UG_Btn_Label from '@salesforce/label/c.UG_Btn_Label';
import UG_Header from '@salesforce/label/c.UG_Header';

export default class UpsellGuidance extends LightningElement {
    
    // variable to store Record Id supplied by the flexipage
    @api recordId;

    //Variable for Spinner
    @track isLoading = false;

    //Variable for Icon
    @track iconVar;

    //Variable to collect custom labels
    label = {
        UG_Amend,
        UG_Renew,
        UG_Btn_Label,
        UG_Header
    };
    
    // Load icon on component load
    connectedCallback(){
       this.iconVar='custom:custom64';
    }
   
    // @wire(getRecord, { recordId: '$recordId', fields: [RENEWAL_OPPTY] })
    // contract;

    // get name() {
    //     return getFieldValue(this.contract.data, RENEWAL_OPPTY);
    // }

   // Button click event handler
   async  handleClick() {
        this.isLoading = true;
        
        // Calls Server side method
        await initiateUpsell({ recordId: this.recordId })

        //success
        .then(results => {
            this.dispatchEvent(new RefreshEvent());
        getRecordNotifyChange([{recordId: this.recordId}]);
            this.isLoading = false;
            const evt = new ShowToastEvent({
                title: 'Upsell Opportunity Creation Has Been Initiated',
                message: 'It may take a few minutes for the process to complete.',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);

            // force page refresh to show Quote renewal status
           // eval("$A.get('e.force:refreshView').fire();");
          
                
        })
        // Error handler
        .catch(error => {
            this.isLoading = false;

            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
                console.log('Error Message:: ' + message);
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while Creating Upsell Opportunity',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
        });
}


}