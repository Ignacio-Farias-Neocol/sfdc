import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import Serial_Number__c from "@salesforce/schema/Case.Serial_Number__c";
import Serial_Account_Id__c from "@salesforce/schema/Case.Serial_Account_Id__c";
import getSubscriptionData from '@salesforce/apex/SubscriptionRelatedListController.fetchActiveRecs';

const columns = [
    {label:"PRODUCT NAME", fieldName:"SBQQ__ProductName__c", type:"text" }, 
    {label:"SUBSCRIPTION END DATE", fieldName:"SBQQ__SubscriptionEndDate__c", type:"date"},
    {
        label: 'SUBSCRIPTION ID',
        fieldName: 'urlLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
    }        
]; // Define your columns

const FIELDS = [
    'Case.Serial_Number__c',
    'Case.Serial__c',
    'Case.Serial_Account_Id__c'
  ];

export default class SusbscriptionActiveRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isRelatedListPageDisplay = false;
    @track sdata = [];
    scolumns = columns;
    showTable = false;
    serialNumber;
    serialAccountId;
    showLoading = true;

    // get record ID from current page reference if not available
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.state.c__Id;
        }
    }


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        if (result.data) {
            this.serialNumber = getFieldValue(result.data, Serial_Number__c);
            this.serialAccountId = getFieldValue(result.data, Serial_Account_Id__c);
            if(this.serialNumber && this.serialAccountId) {
                this.fetchData();
            }  
        } else if (result.error) {
            console.error(result.error);
            this.showLoading = false;
        }
    }

    fetchData(){
		getSubscriptionData({ serialNumber: this.serialNumber, accountId:this.serialAccountId })
		.then(result => {
            if (result) {
                let newArray = JSON.parse(JSON.stringify(result));
                newArray.forEach(res => {
                    res.urlLink = '/' + res.Id;
                });
                if(!this.isRelatedListPageDisplay && newArray.length>0 ) {
                    newArray.length = 3;
                }
                this.sdata = newArray;
            }
            this.showTable = this.sdata.length >0 ? true : false;
            this.showLoading = false;
		})
		.catch(error => {
			console.error(error);
            this.showLoading = false;
		})
        
	} 


   handleOnIconClick(event) {
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'SubscriptionRelatedListPage'
                },
                state: {
                    c__Id: this.recordId
                }
            });
        }
        
}