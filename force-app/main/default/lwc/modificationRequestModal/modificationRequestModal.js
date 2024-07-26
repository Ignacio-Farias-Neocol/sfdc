import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord  } from 'lightning/uiRecordApi';
import {  getObjectInfo, getPicklistValues  } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CreateRequest from "@salesforce/apex/ModificationRequestModalHelper.createRequest";
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Opportunity.Account.Name';
import PRIMARY_QUOTE_NUM_FIELD from '@salesforce/schema/Opportunity.SBQQ__PrimaryQuote__r.Name';
import WILL_NOT_RENEW_DETAILS from '@salesforce/schema/Case.g_Will_Not_Renew_Details__c';
import USER_ACCOUNT_ID from "@salesforce/schema/User.Contact.AccountId";
import USER_ID from "@salesforce/user/Id";
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name'; // Aditya - Added logic to check Community User
import header from '@salesforce/label/c.g_Header';
import modificationTypes from '@salesforce/label/c.g_Modification_Types_Label';
import modifyUserCountDesc from '@salesforce/label/c.g_Change_User_Count_Description';
import modifyUserCountDesc2 from '@salesforce/label/c.g_Change_User_Count_Description2';
import modifyUserCountDesc3 from '@salesforce/label/c.g_Change_User_Count_Description3';
import modifyEndDateDesc from '@salesforce/label/c.g_Co_Term_Modify_End_Date_Description';
import addSubscriptionDesc from '@salesforce/label/c.g_Modify_Subscriptions_Description';
import cancel from '@salesforce/label/c.g_Cancel_Button';
import submit from '@salesforce/label/c.g_Submit_Button';
import errorMessage from '@salesforce/label/c.g_Error_Message';
import successMessage from '@salesforce/label/c.g_Success_Message';
import userCountDetailsLabel from '@salesforce/label/c.g_Change_User_Count_Instructions';
import coTermModifyEndDateDetailLabel from '@salesforce/label/c.g_Co_Term_Modify_End_Date_Instructions';
import modifySubsDetailLabel from '@salesforce/label/c.g_Modify_Subscriptions_Instructions';
import willNotRenewDetailLabel from '@salesforce/label/c.g_Will_Not_Renew_Instructions';
import otherDetailLabel from '@salesforce/label/c.g_Other_Instructions';
import willNotRenewDesc from '@salesforce/label/c.g_Will_Not_Renew_Description';
import otherDesc from '@salesforce/label/c.g_Other_Description';
import selectionInstructions from '@salesforce/label/c.g_Selection_Instructions';
import communityQuote from '@salesforce/label/c.g_Community_Quote';

import CASE_OBJECT from '@salesforce/schema/Case';

const fields = [ACCOUNT_NAME_FIELD, PRIMARY_QUOTE_NUM_FIELD];

export default class ModificationRequestModal extends LightningElement {
    @track showModal = false;
    saveRecord = false; // check if any data is available to create Case
    caseRecordTypeId ;
    spinnerVisibility = false;

    label = {
        header, 
        modificationTypes, 
        modifyUserCountDesc, 
        modifyUserCountDesc2,
        modifyUserCountDesc3,
        modifyEndDateDesc, 
        addSubscriptionDesc, 
        cancel, 
        submit,
        userCountDetailsLabel,
        coTermModifyEndDateDetailLabel,
        modifySubsDetailLabel,
        willNotRenewDetailLabel,
        otherDetailLabel,
        willNotRenewDesc,
        otherDesc,
        selectionInstructions
    };

    renewValues = [];
    
    userCountApi;
    userCount;
    coTermModifyEndDate;
    subsDetail = null;
    willNotRenew;
    otherDetail = null;

    caseInputFields = {};

    qty = 0;
    qtyVal='0';

    @track opportunityId; // ID of the renewal Opportunity
    @track accountId; // ID of the current User's Account 

    @track showChangeUserCount = false;
    @track showCoTerm = false;
    @track showCoTermEndDate = false;
    @track showModifySubs = false;
    @track showWillNotRenew = false;
    @track showOther = false;

    caseObj;
    error;

    userCountLabel;
    coTermModifyEndDateLabel;
    coTermModifyEndDateDetailLabel;
    modifySubsLabel;
    modifySubsDetailLabel;
    willNotRenewLabel;
    willNotRenewDetailLabel;
    otherLabel;
    otherDetailLabel;
    subheader;

    @track caseObj;
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT}) 
    caseObj(result1) {
        if (result1.data) {
            this.caseObj = result1.data;
            this.userCountLabel = this.caseObj.fields.g_Change_User_Count__c.label;
            //this.userCountDetailsLabel = this.caseObj.fields.g_Change_User_Count_Details__c.label;
            this.coTermModifyEndDateLabel = this.caseObj.fields.g_Co_Term_Modify_End_Date__c.label;
            //this.coTermModifyEndDateDetailLabel = this.caseObj.fields.g_Co_Term_Modify_End_Date_Details__c.label;
            this.modifySubsLabel = this.caseObj.fields.g_Modify_Subscriptions__c.label;
            //this.modifySubsDetailLabel = this.caseObj.fields.g_Modify_Subscriptions_Detail__c.label;
            this.willNotRenewLabel = this.caseObj.fields.g_Will_Not_Renew__c.label;
            //this.willNotRenewDetailLabel = this.caseObj.fields.g_Will_Not_Renew_Details__c.label;
            this.otherLabel = this.caseObj.fields.g_Other__c.label;
            //this.otherDetailLabel = this.caseObj.fields.g_Other_Details__c.label;
            this.caseRecordTypeId = Object.keys(this.caseObj.recordTypeInfos).find(rti => this.caseObj.recordTypeInfos[rti].name === communityQuote);
        } else if (result1.error) {
            this.error = result1.error;
            console.log('error...'+this.error);
        }
    }

    @wire(getRecord, { recordId: USER_ID, fields: [USER_ACCOUNT_ID] })
    user;

    get userAccountId() {
        return getFieldValue(this.user.data, USER_ACCOUNT_ID);
    }

    willNotRenewOptions = [];
    @wire(getPicklistValues, { recordTypeId: '$caseRecordTypeId', fieldApiName: WILL_NOT_RENEW_DETAILS })
    willNotRenew(result) {
        if(result.data) {
            for(const option of result.data.values) {
                this.willNotRenewOptions.push({label: option.label, value: option.value});
            }
        }
    }

    @api showModalPopup(opportunityId,accountId,accountName,quoteNum){
        console.log('in show modal...'+opportunityId+' '+accountId+' '+quoteNum);
        this.opportunityId = opportunityId ? opportunityId : '';
        this.accountId = accountId ? accountId : '';
        this._accName = accountName;
        this._quoteNum = quoteNum;

        this.subHeader = this.accName;

        this.subHeader += this._quoteNum ? ', ' + this._quoteNum : '';

        this.showModal = true; 
    }
    
    _accName
    get accName(){
        // if(this.record) return getFieldValue(this.record,ACCOUNT_NAME_FIELD);
        return this._accName;
    }

    _quoteNum
    get quoteNum(){
        // if(this.record) return getFieldValue(this.record,PRIMARY_QUOTE_NUM_FIELD);
        this._quoteNum;
    }

    handleChangeUserCount(event){
        if(event.target.checked){
            this.showChangeUserCount = true;
            //this.caseInputFields[this.caseObj.fields.userCountLabel.apiName] = true;
        }
        else{
            this.showChangeUserCount = false;
            this.userCount ='';
            //this.caseInputFields[this.caseObj.fields.userCountLabel.apiName] = false;
        }
    }

    handleCoTerm(event){
        if(event.target.checked){
            this.showCoTerm = event.target.checked;
        }
        else{
            this.showCoTerm = event.target.checked;
            this.coTermModifyEndDate ='';        
        }
    }
    
    handleModifSubs(event){
        if(event.target.checked){
            this.showModifySubs = event.target.checked;
        }
        else{
            this.showModifySubs = event.target.checked;
            this.subsDetail = '';
        }
    }
    
    handleWillNotRenew(event){
        if(event.target.checked){
            this.showWillNotRenew = event.target.checked;
        }
        else{
            this.showWillNotRenew = event.target.checked;
        }
    }
    
    handleOther(event){
        if(event.target.checked){
            this.showOther = event.target.checked;
        }
        else{
            this.showOther = event.target.checked;
            this.otherDetail='';
        }
    }

    handleChangeUserCountDetail(event){
        this.userCount = event.target.value;
    }

    handleChangeSubsDetail(event){
        this.subsDetail = event.target.value;
    }

    handleChangeCoTermModifyEndDate(event){
        this.coTermModifyEndDate = event.target.value;
    }

    handleChangeWillNotRenew(event){
        this.willNotRenew = event.target.value.join(';');
    }

    handleChangeOtherDetail(event){
        this.otherDetail = event.target.value;
    }

    hideModal() {
        // Setting boolean variable to false, this will hide the Modal
        console.log('hidemoda...');
        this.resetFieldValues();
        this.showModal = false;
    }

    handleSubmit(){
        console.log('inside handleSubmit...');
        this.spinnerVisibility = true;
        this.setFieldValues();
        if(this.saveRecord){
            // Aditya - Added logic based on Community User - Start
            if(this.isCommunityUser){
                this.caseInputFields['isCommunityUser'] = this.isCommunityUser;
            }else{
                this.caseInputFields['isCommunityUser'] = this.isCommunityUser;
                this.caseInputFields[this.caseObj.fields.Opportunity_for_SE_Cases__c.apiName] = this.opportunityId;
            }
            // Aditya - Added logic based on Community User - End
            this.caseInputFields[this.caseObj.fields.AccountId.apiName] = this.userAccountId;
            this.caseInputFields[this.caseObj.fields.Related_Account__c.apiName] = this.accountId;
            this.caseInputFields[this.caseObj.fields.RecordTypeId.apiName] = this.caseRecordTypeId;
            var quoteNum = this._quoteNum == undefined ? '' : this._quoteNum; // Aditya - to handle undefined value  
            this.caseInputFields[this.caseObj.fields.Subject.apiName] = 'Modification Request for '+this._accName +', '+ quoteNum;
            //4. Prepare config object with object and field API names 
            const recordInput = {
            apiName: CASE_OBJECT.objectApiName,
            fields: this.caseInputFields
            };
            console.log('record input..'+JSON.stringify(recordInput));    
            //5. Invoke createRecord by passing the config object
            CreateRequest({fields: this.caseInputFields})
            .then(result => {
                console.log('Success...'+result);
                this.spinnerVisibility = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: successMessage,
                        variant: 'success',
                    }),
                );
                this.publishRecordCreatedEvent();
                this.hideModal();
            })
            .catch(error => {
                console.log('Error...'+JSON.stringify(error));
                this.spinnerVisibility = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: errorMessage,
                        variant: 'error',
                    }),
                );
            }) 
        }else{
            console.log('No data to create record');
            this.spinnerVisibility = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: errorMessage,
                    variant: 'error',
                }),
            );
        }
        
    }

    setFieldValues(){
        console.log('inside setFieldValues...'+this.template.querySelectorAll(".toplevelcheckbox"));
        //let firstClass = this.template.querySelector(".parentclass");
        let toplevelcheckboxes = this.template.querySelectorAll(".toplevelcheckbox");
        var checkbox_array = [...toplevelcheckboxes]; // converts NodeList to Array
        checkbox_array.forEach(checkbox => {
            if(checkbox.checked){
                this.saveRecord = true;
                console.log('label...'+checkbox.label);
                if(checkbox.label === this.userCountLabel){
                    this.caseInputFields[this.caseObj.fields.g_Change_User_Count__c.apiName] = true;
                    this.caseInputFields[this.caseObj.fields.g_Change_User_Count_Details__c.apiName] = this.userCount;
                }else if(checkbox.label === this.coTermModifyEndDateLabel){
                    this.caseInputFields[this.caseObj.fields.g_Co_Term_Modify_End_Date__c.apiName] = true;
                    this.caseInputFields[this.caseObj.fields.g_Co_Term_Modify_End_Date_Details__c.apiName] = this.coTermModifyEndDate;
                }else if(checkbox.label === this.modifySubsLabel){
                    this.caseInputFields[this.caseObj.fields.g_Modify_Subscriptions__c.apiName] = true;
                    this.caseInputFields[this.caseObj.fields.g_Modify_Subscriptions_Detail__c.apiName] = this.subsDetail;
                }else if(checkbox.label === this.willNotRenewLabel){
                    this.caseInputFields[this.caseObj.fields.g_Will_Not_Renew__c.apiName] = true;
                    this.caseInputFields[this.caseObj.fields.g_Will_Not_Renew_Details__c.apiName] = this.willNotRenew.toString();
                }else if(checkbox.label === this.otherLabel){
                    this.caseInputFields[this.caseObj.fields.g_Other__c.apiName] = true;
                    this.caseInputFields[this.caseObj.fields.g_Other_Details__c.apiName] = this.otherDetail;
                }
            }
        });
    }

    resetFieldValues(){
        console.log('inside resetFieldValues...');
        //let firstClass = this.template.querySelector(".parentclass");
        this.saveRecord =false;
        this.userCount ='';
        this.showChangeUserCount = false;
        this.coTermModifyEndDate ='';
        this.showCoTerm = false;
        this.showModifySubs =false;
        this.subsDetail = '';
        this.showWillNotRenew = false;
        this.otherDetail='';
        this.showOther = false;
    }
    
    setDecrementCounter(event){
        if(this.qty == 0)   this.qty = 0;
        else    this.qty = this.qty - 1;
        this.qtyVal = this.qty.toString();
    }

    setIncrementCounter(event) {
        this.qty = this.qty + 1;
        this.qtyVal = this.qty.toString();
    }


    quantityCtrl(event) {
        this.qty = event.detail;
    }

    publishRecordCreatedEvent() {
        console.log('requestcreated event');
        //Create an event
        const filterEvent = new CustomEvent("requestcreated", {
            detail: {parentOppId: this.opportunityId}
        });
    
        //Raise an event
        this.dispatchEvent(filterEvent);
    }

    // Aditya - Added logic to check Community User
    profileName;
    error;
    @track isCommunityUser = false;
    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME_FIELD]}) 
    userDetails({error, data}) {
        if (data) {
            this.profileName = data.fields.Profile.value.fields.Name.value; ;
            console.log('profileName...'+this.profileName);
            if(this.profileName == 'Apollo: MFA Barracuda CCPlus Admin Login Profile' || 
                this.profileName == 'Customer Community Plus Login User' ||
                this.profileName == 'Apollo: Barracuda CCPlus Admin Login Profile' || 
                this.profileName == 'Apollo: Barracuda CCPlus Login Profile'
                ){
                this.isCommunityUser = true;
            }
        } else if (error) {
            this.error = error ;
        }
    }

}