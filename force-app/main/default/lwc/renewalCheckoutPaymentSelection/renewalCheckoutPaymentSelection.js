import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord  } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    FlowNavigationBackEvent,
    FlowNavigationNextEvent
  } from 'lightning/flowSupport';
import USER_ID from "@salesforce/user/Id";
import DEFFAULT_PAYMENT_TERMS from '@salesforce/schema/SBQQ__Quote__c.Default_Payment_Terms__c';
import OPPORTUNITY_ID from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Opportunity2__c';
import ACCOUNT_ID from '@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c';
import getCreditCards from '@salesforce/apex/RenewalCheckoutHelper.getCreditCards';
import { refreshApex } from '@salesforce/apex';
import ACCOUNT_TYPE from '@salesforce/schema/User.Contact.Account.Type';
import PARTNER_LEVEL from '@salesforce/schema/User.Contact.Account.Partner_Level__c';
import BILL_TO_EMAIL from '@salesforce/schema/User.Contact.Account.Bill_To_Email__c';
import validPONumber from '@salesforce/apex/RenewalCheckoutHelper.validPONumber';

import termsAndCondition1 from '@salesforce/label/c.g_Terms_And_Conditions1';
import termsAndCondition2 from '@salesforce/label/c.g_Terms_And_Conditions2';
import termsAndCondition3 from '@salesforce/label/c.g_Terms_and_Conditions3';

const fields = [ACCOUNT_TYPE, PARTNER_LEVEL, BILL_TO_EMAIL];

export default class RenewalCheckoutPaymentSelection extends LightningElement {

    @api selectedCreditCard;
    @api poNumber;
    @api autoRenew;
    @api opportunityId;
    @api accountId;
    @api quoteId;

    selectedPaymentType;
    @track userId;
    @track showPOInput = true;
    @track poValue;
    @track showCCInput = true;
    @track creditCardValue;
    @track poSelected = false;
    @track ccSelected = false;
    @track isCreditCardsAvailable = false;

    @track emailToBeSentTo;

    //Flow Navigation Vars
    @api availableActions = [];

    opportunityId;

    spinnerVisibility = true;

    label = {
        termsAndCondition1, 
        termsAndCondition2, 
        termsAndCondition3
    }
    connectedCallback() {
        console.log('quoteid in connectedcallback...'+this.quoteId);
        this.userId = USER_ID; //'0053I000001Q5NbQAK';
        this.spinnerVisibility = false;
    }

    /* TODO: check if PO or CC is selected, check if agreedToTermsAndConditions is seleced */
    @api
    validate() {
        let errMessage;
        if(((this.isPOEligible && this.poSelected && this.poNumber) || (this.ccSelected && this.selectedCreditCard)) && this.agreedToTermsAndConditions) { 
            if(this.poSelected) {
                this.selectCreditCardPayment = null;
                this.validatePONumber();
            } else if(this.ccSelected) {
                this.poNumber = null;
                this.handleNext();
            }
        } 
        else { 
            if(this.isPOEligible && this.poSelected && !this.poNumber){
                errMessage = 'Please enter a PO Number to proceed';
            }
            else if(this.ccSelected && !this.selectedCreditCard){
                errMessage = 'Please select a Credit Card to proceed';
            }  
            else if((this.isPOEligible && this.poSelected && this.poNumber) && (this.ccSelected && this.selectedCreditCard) && !this.agreedToTermsAndConditions){
                errMessage = 'Please agree to Terms and Conditions to proceed';
            }            
            else{
                errMessage = 'Please select a payment option and agree to Terms and Conditions to proceed';
            }
            if(errMessage) {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: errMessage,
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }
        }
    }
    // String poNumber, String accountId, String quoteId
    validatePONumber(){
        this.spinnerVisibility = true;
        validPONumber({poNumber: this.poNumber, accountId: this.accountId, quoteId: this.quoteId}).then(result => {
			if(result) {
                this.spinnerVisibility = false;
                this.handleNext();
            } else {
                this.spinnerVisibility = false;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Duplicate PO Number found. Please provide a different PO Number',
                    variant: 'error',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }
        })
        .catch(error => {
            this.spinnerVisibility = false;
            console.log('error...' + JSON.stringify(error));
			const evt = new ShowToastEvent({
                title: 'Error',
                message: 'There was an error validating the PO Number. Please reach out to {0} for support.',
                messageData: [
                    {
                        url: 'community_help@barracuda.com',
                        label: 'community_help@barracuda.com' 
                    }
                ],
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent(evt);
        });
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.urlStateParameters = currentPageReference.state;
          this.setParametersBasedOnUrl();
       }
    }

    setParametersBasedOnUrl() {
        this.quoteId = this.urlStateParameters.quoteId || null;// 'a1Y3I000000bGBZUA2';
        this.accountId = this.urlStateParameters.accountId || null; 
        console.log('QuoteId...'+this.quoteId);
        console.log('accountId...'+this.accountId);
    }

    get optionsPONumber() {
        return [
            { label: 'PO Number', value: 'PO Number' }
        ];
    }

    get optionsCreditCard() {
        return [
            { label: 'Credit Card', value: 'Credit Card' }
        ];
    }

    creditCardOptions = [];
    _wiredCreditCardData;
    @wire(getCreditCards)
    wiredCreditCards(wireResult){
        const { error, data } = wireResult;
        this._wiredCreditCardData = wireResult;
        if (data) {
            console.log('data...'+JSON.stringify(data));
            var creditCards = [];
            Object.keys(data).forEach(function(key) {
                
                //Filter out expired cards
                let expDate = data[key].Expiration__c;
                let expMonth = expDate.split('/')[0];
                let expYear = expDate.split('/')[1];

                let today = new Date();
                //getMonth() returns 0-11. Need to increment by 1
                let month = String(today.getMonth() + 1).padStart(2, '0');
                let year = String(today.getFullYear()).substring(2);

                if(expYear < year) {
                    return;
                } else if (expYear === year) {
                    if(expMonth < month) {
                        return;
                    }
                }

                var cardDetails = data[key].Card_Type__c ? data[key].Card_Type__c : '';
                cardDetails += data[key].Last_4_of_CC__c ? ' ending in ' + data[key].Last_4_of_CC__c : '';
                cardDetails += data[key].Expiration__c ? ', Exp: '+data[key].Expiration__c : '';
                creditCards.push({label : cardDetails, value:data[key].Id });
            });
            this.creditCardOptions = creditCards; 
            this.isCreditCardsAvailable = true;
        } else if (error) {
            console.log('Error getting cards...'+JSON.stringify(error));
            this.creditCardOptions = undefined;
        }
    }

    refreshCreditCard(event){
        refreshApex(this._wiredCreditCardData);
        console.log('after refreshCreditCard...'+this.creditCardOptions); 
    }

    contact;
    @wire(getRecord, { recordId: '$userId', fields: fields }) 
    wireddataContact(result){
        if(result.data){
            let contactDetails = result.data.fields.Contact.value.fields.Account.value;
            console.log('result.data.fields.Partner_Level__c...'+contactDetails.fields.Partner_Level__c.value);
            console.log('result.data.fields.Type...'+contactDetails.fields.Type.value);
            if((contactDetails.fields.Partner_Level__c.value === 'Affiliate' && contactDetails.fields.Type.value === 'Partner - Reseller') || (contactDetails.fields.Type.value === 'Customer')){
                this.showTermsAndConditions = true;
            }
            this.emailToBeSentTo = 'Final order confirmation will be emailed to: ' + contactDetails.fields.Bill_To_Email__c.value;
        }
        else{
            console.log('account error...'+result.error);
        }
    }

    quoteRecord;
    @track isPOEligible = false;
    @wire(getRecord, { recordId: '$quoteId' , fields: [DEFFAULT_PAYMENT_TERMS, OPPORTUNITY_ID, ACCOUNT_ID] }) 
    wireddataQuote(result){
        if(result.data){
            this.quoteRecord = result.data;
            console.log('Oppt details..'+this.quoteRecord.fields.Default_Payment_Terms__c.value);
            let paymentTerms = this.quoteRecord.fields.Default_Payment_Terms__c.value;
            if(paymentTerms.startsWith('Net ')){
                this.isPOEligible = true;
            }

            this.opportunityId = this.quoteRecord.fields.SBQQ__Opportunity2__c.value;
            this.accountId = this.quoteRecord.fields.SBQQ__Account__c.value
            console.log('accountId in data quote...'+this.accountId);
        }
        else{
            console.log('error...'+JSON.stringify(result.error));
        }
    }

    selectPONumberPayment(event){
        this.showPOInput = true;
        this.selectedPaymentType = 'PO';
        this.poValue = event.target.value;

        this.creditCardValue = undefined;
        this.selectedCreditCard = '';
        this.poSelected = true;
        this.ccSelected = false;
    }

    selectCreditCardPayment(event){
        this.showCCInput = true;
        this.selectedPaymentType = 'CC';
        this.creditCardValue = event.target.value;

        this.poValue = undefined;
        this.poValue = '';
        this.poSelected = false;
        this.ccSelected = true;
    }

    onSelectCreditCard(event){
        this.selectedCreditCard = event.target.value;
    }

    handleAutoRenew(event){
        this.autoRenew = event.target.checked;
    }

    handleTermsAndCondition(event){
        this.agreedToTermsAndConditions = event.target.checked;
    }

    handlePONumber(event) {
        this.poNumber = event.target.value;
    }

    addCreditCard(){
        console.log('in add credit card...'+this.accountId);
        this.template.querySelector('c-credit-card-entry-l-w-c').getURLwithKey(this.accountId);
    }

    handlePrevious(){
        // check if BACK is allowed on this screen
        if (this.availableActions.find((action) => action === 'BACK')) {
          // navigate to the next screen
          const navigateBackEvent = new FlowNavigationBackEvent();
          this.dispatchEvent(navigateBackEvent);
        }
      }
    
    handleNext(){
    // check if Next is allowed on this screen
        this.spinnerVisibility = false;
        if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }
}