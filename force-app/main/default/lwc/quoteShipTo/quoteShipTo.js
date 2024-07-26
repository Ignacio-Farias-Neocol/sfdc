import { LightningElement, api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAddress from '@salesforce/apex/QuoteAddressSelectorController.getAddress';
import UpdAddressOnQuote from '@salesforce/apex/QuoteAddressSelectorController.UpdAddressOnQuote';

export default class QuoteShipTo extends LightningElement {
    data;
    error;
    value = '';
    ShipCheckboxChecked=false;
    @api showShipAdd;
    @api quoteRecord;
    @api addressOptions;
    @api selectedShipToSource = 'account';
    @api recordId;
    @track isDataLoading = false;
    @track ShipAddress;
    @track accountShipAddressMap={};
    @track showAvaiShipAdd;
    @track shipid;
    @track shipAddId;

    handleChangeShipTo(event) {
        this.value = event.detail.value;
        this.isDataLoading =true;
        let optLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        optLabel = optLabel.split(':')[0];
        optLabel = optLabel.toLowerCase();
        this.selectedShipToSource = optLabel;
        console.log('child ship this.value*'+this.value);
        getAddress({Accountid: this.value, addressType: 'ShipTo'})
        .then(result => {
          this.ShipAddress = result;
          this.showAvaiShipAdd = true;
          this.isDataLoading =false;
          this.accountShipAddressMap[this.value]=result;
        })
        .catch(error => {
            this.error = error;
        });
    }
    get QuoteAddOptions() {
        console.log(this.addressOptions);
        return this.addressOptions;
    }
    get AvaiShipAdd(){
        return this.showAvaiShipAdd && !this.isDataLoading;
    }
    onShipToCheckboxChange(event){
        const check = event.target.checked;
        this.shipid = event.currentTarget.dataset.id;
        const boxes = this.template.querySelectorAll('lightning-input');
        this.shipAddId =  event.target.name ;
        console.log('shipAddId*',this.shipAddId);
        boxes.forEach(box => box.checked = event.target.name === box.name);
        for (let i = 0; i < boxes.length; i++) {
            let box = boxes[i];
            console.log('box name'+box.name);
            console.log('box name'+box.checked);
        }
        console.log('Child Event id*****',this.shipid);
        if(this.shipid!==undefined && this.shipid!==null && this.shipAddId!==null && this.shipAddId!==undefined){
          this.ShipCheckboxChecked=true;
        }
        else{
          this.ShipCheckboxChecked=false;
        }
    }
    handleUpdateShipTo(event) {
        if(this.shipid!==undefined && this.shipid!==null && this.ShipCheckboxChecked){
          this.isDataLoading =true;
          console.log('Child shipid**'+this.shipid);
          console.log('Child accountShipAddressMap**'+ JSON.stringify(this.accountShipAddressMap));
          let theAddress = this.accountShipAddressMap[this.shipid];
          var jsonAddress = JSON.stringify(theAddress);
          var qRecord = JSON.stringify(this.quoteRecord);
          console.log('Child quRecord'+qRecord);
          console.log('Child jsonAddress**'+jsonAddress);
          UpdAddressOnQuote({addressId: this.shipAddId, quoteRecord: qRecord, addressType: 'shipTo', addressObj: jsonAddress})
          .then(result => {
            if(result!=null){
            this.quoteRecord = result;
            }
            this.isDataLoading =false;
            console.log('**Child handleUpdateShipTo run succesfully*'+JSON.stringify(result));
            console.log('**Child check quoterecord**'+JSON.stringify(this.quoteRecord));
          })
          .catch(error => {
              this.error = error;
          });
        }
        else{
          alert("Please choose an address");
        }
    }
    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: event.detail.apiName + ' Updated.',
                variant: 'success',
            })
        );
    }
    closeModal() {
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}