import { LightningElement,api,wire } from 'lwc';
import TECHNICAL_ALERT_FIELD from '@salesforce/schema/Account.Technical_Alert__c';
import CONTACT_CENTER_ALERT_FIELD from '@salesforce/schema/Account.Contact_Center_Alert__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
export default class Account_Service_Alert extends LightningElement {
		@api recordId;
		technicalAlert
		contactCenterAlert
		isRender=false;

		 @wire(getRecord, {
        recordId: '$recordId',
        fields: [TECHNICAL_ALERT_FIELD, CONTACT_CENTER_ALERT_FIELD]
    })
    accountRecord({ error, data }) {
        if (data) {
            this.technicalAlert = getFieldValue(data, TECHNICAL_ALERT_FIELD);
            this.contactCenterAlert = getFieldValue(data, CONTACT_CENTER_ALERT_FIELD);

			if((this.technicalAlert!=null && this.technicalAlert!=undefined)||(this.contactCenterAlert!=null && this.contactCenterAlert!=undefined)){
						this.isRender=true;
			}

        }
    }

}