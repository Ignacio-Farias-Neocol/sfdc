import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import RENEWED_CONTRACT_ID from '@salesforce/schema/Case.Opportunity_for_SE_Cases__r.SBQQ__RenewedContract__c';

export default class CaseCommunityQuoteNavToContract extends NavigationMixin(LightningElement) {

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [RENEWED_CONTRACT_ID] })
    case;

    get hasRenewedContract() {
        console.log('checking for contract');
        if(getFieldValue(this.case.data, RENEWED_CONTRACT_ID)) {
            return true;
        } else {
            return false;
        }
    }

    navigateToContract() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: getFieldValue(this.case.data, RENEWED_CONTRACT_ID),
                actionName: 'view'
            }
        });
    }
}