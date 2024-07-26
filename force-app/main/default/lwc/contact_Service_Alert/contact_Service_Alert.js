import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from '@salesforce/schema/Contact.AccountId';
import getParentAccount from '@salesforce/apex/RetrieveParentAccountInfoController.getParentAccount';
import ACCtech_ALERT_FIELD from '@salesforce/schema/Account.Technical_Alert__c';
import ACCcontact_CENTER_ALERT_FIELD from '@salesforce/schema/Contact.Account.Contact_Center_Alert__c';

export default class contactServiceAlerts extends LightningElement {
    @api recordId;
    technicalAlert;
    contactCenterAlert;
    contactAlert;
    error;
    isRender=false;

    connectedCallback() {
       console.log('Print recordId ***', this.recordId);

       getParentAccount({ contactId: this.recordId })
            .then((result) => {
                console.log('result***',JSON.stringify(result));
                
                this.technicalAlert = result.Account.Technical_Alert__c;
                console.log('result***',this.technicalAlert);
                this.contactCenterAlert = result.Account.Contact_Center_Alert__c;
                console.log('result***',this.contactCenterAlert);
                this.contactAlert = result.Contact_Alert__c;
                console.log('result***',this.contactAlert);
                
                if((this.technicalAlert != null && this.technicalAlert != undefined) || 
                (this.contactCenterAlert != null && this.contactCenterAlert != undefined)|| 
                (this.contactAlert != null && this.contactAlert != undefined)){
                    this.isRender = true;
                }

            })
            .catch((error) => {
                this.error = error;
                console.log('Error***',error);
            });

    }
  
}