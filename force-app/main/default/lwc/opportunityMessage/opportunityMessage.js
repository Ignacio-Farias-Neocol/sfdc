import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OpportunityMessage extends LightningElement {
    @api recordId;
    connectedCallback() {
        console.log('This is Sudipta');
        const evt = new ShowToastEvent({
            mode: 'sticky',
            title: 'Attention',
            message: 'This amendment is out of date.  Please re-create.',
            variant: 'warning'
        });
        this.dispatchEvent(evt);
    }
}