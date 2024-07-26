import { LightningElement, api, wire,track } from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import getQuote from '@salesforce/apex/QuoteAddressSelectorController.getQuote';

export default class QuoteAddressSelectorV1 extends LightningElement {
  data;
  error;
  @track recordId;
  @track QuoteRecord;
  @track showQuote = false;
  @track showAccount = false;
  @track showReseller = false;
  @track showDist = false;
  @track isDataLoading = true;
  @track showBillAdd = false;
  @track showShipAdd =false;
  @track Addressoptions = [];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    @api invoke() {
        console.log("Bill To/Ship on Quote Workings312");
      }
      @wire(getQuote,{recordId: '$recordId'})
      wiredQuote({ error, data }) {
          if (data) {
            var QData = data.qRecord;
            this.QuoteRecord=data.qRecord;
            console.log("data*", data);
            console.log("parent component");
            this.showQuote=true;
            this.isDataLoading=false;
            console.log("QuoteData",QData);
            console.log("QuoteData res***",QData.SBCF_Reseller__c);
            this.Addressoptions = [];
            if(QData.SBQQ__Distributor__c!=null && QData.SBQQ__Distributor__c!=undefined ){
              this.showDist =true;
              this.Addressoptions.push({value: QData.SBQQ__Distributor__c , label: 'Distributor: '+QData.SBQQ__Distributor__r.Name})
            }
            if(QData.SBCF_Reseller__c!=null && QData.SBCF_Reseller__c!=undefined){
                this.showReseller =true;
                this.Addressoptions = [...this.Addressoptions ,{value: QData.SBCF_Reseller__c , label: 'Reseller: '+QData.SBCF_Reseller__r.Name}]; 
            }
            if(QData.SBQQ__Account__c!=null && QData.SBQQ__Account__c!=undefined){
              this.showAccount =true;
              this.Addressoptions = [...this.Addressoptions ,{value: QData.SBQQ__Account__c , label: 'Account: '+QData.SBQQ__Account__r.Name}]; 
            }
            if(QData.Billing_Address__c!=null && QData.Billing_Address__c!=undefined ){
                this.showBillAdd = true;
            }
            if(QData.Shipping_Address__c!=null && QData.Shipping_Address__c!=undefined ){
              this.showShipAdd = true;
            }
          } else if (error) {
              this.error = error;
              console.log("Error occured",this.error);
          }
      };
    }