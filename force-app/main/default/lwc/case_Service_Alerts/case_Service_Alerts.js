import { LightningElement, api,wire } from 'lwc';

import Contact_ALERT_FIELD from '@salesforce/schema/Case.Contact_Alert_1__c';
import CONTACT_CENTER_ALERT_FIELD from '@salesforce/schema/Case.Contact_Center_Alert__c';
import TECHNICAL_ALERT_FIELD from '@salesforce/schema/Case.Technical_Alert__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';


export default class Service_Alerts extends LightningElement {
    @api recordId;
    technicalAlert;
    contactCenterAlert;
    ContactAlert;
    isRender=false;

@wire(getRecord, {
        recordId: '$recordId',
        fields: [TECHNICAL_ALERT_FIELD, CONTACT_CENTER_ALERT_FIELD,Contact_ALERT_FIELD]
    })
    getCaseRecord({ error, data }) {
        if (data) {
            this.technicalAlert = getFieldValue(data, TECHNICAL_ALERT_FIELD);
            this.contactCenterAlert = getFieldValue(data, CONTACT_CENTER_ALERT_FIELD);
            this.ContactAlert = getFieldValue(data, Contact_ALERT_FIELD);

            if((this.technicalAlert!=null && this.technicalAlert!=undefined) || (this.contactCenterAlert!=null && this.contactCenterAlert!=undefined) ||(this.ContactAlert!=null && this.ContactAlert!=undefined)){

                        this.isRender=true;

            }
        }
    }
}