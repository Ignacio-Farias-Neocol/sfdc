import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import searchLeadsBySuppliedEmail from '@salesforce/apex/WebCase_LeadSearch.searchLeadsBySuppliedEmail';

export default class WebCase_LeadSearch extends LightningElement {
    @api recordId;
    @track suppliedEmail;
    @track leads;
    @track showLeads = false;

    @wire(getRecord, { recordId: '$recordId', fields: ['Case.SuppliedEmail'] })
    caseRecord({ error, data }) {
        if (data) {
            this.suppliedEmail = getFieldValue(data, 'Case.SuppliedEmail');
            console.log('caseemail:', data);
            this.searchLeads();
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: ['LiveChatTranscript.Email__c'] })
    chatRecord({ error, data }) {
        if (data) {
            this.suppliedEmail = getFieldValue(data, 'LiveChatTranscript.Email__c');
            console.log('email:', data);
            this.searchLeads();
        } else if (error) {
            console.error(error);
        }
    }

    searchLeads() {
        searchLeadsBySuppliedEmail({ suppliedEmail: this.suppliedEmail })
            .then(result => {
                console.log('Leads:', result);
                this.leads = result;
                if (this.leads.length === 1) {
                    this.showLeads = true;
                } else {
                    this.showLeads = this.leads.length > 0;
                }
            })
            .catch(error => {
                console.error(error);
            });
    }

    get leadLink() {
        if (this.leads && this.leads.length > 0) {
            return `/lightning/r/Lead/${this.leads[0].Id}/view`;
        }
        return null;
    }
}