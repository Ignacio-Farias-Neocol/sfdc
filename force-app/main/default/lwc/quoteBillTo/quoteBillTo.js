import { LightningElement, api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAddress from '@salesforce/apex/QuoteAddressSelectorController.getAddress';
import UpdAddressOnQuote from '@salesforce/apex/QuoteAddressSelectorController.UpdAddressOnQuote';

export default class QuoteBillTo extends LightningElement {
    data;
    error;
    value = '';
    BillAddress;
    BillCheckboxChecked=false;
    @api showadd;
    @api qt;
    @track billchecked={};
    @api addressOptions;
    @track isDataLoading = false;
    @track showBillAdd = false;
    @track showAvaiBillAdd = false;
    @track billid;
    @track billAddId;
    @track AccountbillAddressMap={};
    @track BillToValue='';
    renderedCallback() {
      console.log('addressOptions****'+this.addressOptions.length);
      if(this.addressOptions.length>0){
        this.BillToValue = this.addressOptions[0].value;
        this.getBillToAddress(this.BillToValue);
      }
    }
    getBillToAddress(accId){
      getAddress({Accountid: accId, addressType: 'billTo'})
        .then(result => {
          this.BillAddress = result;
          this.showAvaiBillAdd = true;
          this.isDataLoading =false;
          this.AccountbillAddressMap[this.value]=result;
        })
        .catch(error => {
            this.error = error;
        });
    }
    handleChangeBillTo(event) {
        this.value = event.detail.value;
        this.isDataLoading =true;
        console.log('child this.value**'+this.value);
        this.getBillToAddress(this.value);
    }
    get QuoteAddOptions() {
        console.log(this.addressOptions);
        return this.addressOptions;
    }
    get AvaiBillAdd(){
        return this.showAvaiBillAdd && !this.isDataLoading;
    }
    onBillToCheckboxChange(event){
        const check = event.target.checked;
        this.billid = event.currentTarget.dataset.id;
        const boxes = this.template.querySelectorAll('lightning-input');
        this.billAddId =  event.target.name ;
        console.log('billAddId*',this.billAddId);
        boxes.forEach(box => box.checked = event.target.name === box.name);
        console.log('Child Event checked***',check);
        console.log('Child Event id*****',this.billid);
        if(this.billid!==undefined && this.billid!==null && this.billAddId!==null && this.billAddId!==undefined ){
          this.BillCheckboxChecked=true;
        }
        else{
          this.BillCheckboxChecked=false;
        }
    }
    handleUpdateBillTo(event) {
        if(this.billid!==undefined && this.billid!==null && this.BillCheckboxChecked){
          this.isDataLoading =true;
          console.log('Child billid**'+this.billid);
          console.log('Child AccountbillAddressMap**'+ JSON.stringify(this.AccountbillAddressMap));
          let theAddress = this.AccountbillAddressMap[this.billid];
          var jsonAddress = JSON.stringify(theAddress);
          var qRecord = JSON.stringify(this.qt);
          console.log('Child quRecord'+qRecord);
          console.log('Child jsonAddress**'+jsonAddress);
          UpdAddressOnQuote({addressId: this.billAddId, quoteRecord: qRecord, addressType: 'billTo', addressObj: jsonAddress})
          .then(result => {
            if(result!=null){
            this.qt = result;
            }
            this.isDataLoading =false;
            console.log('**Child handleUpdateBillTo run succesfully*'+JSON.stringify(result));
            console.log('**Child check quoterecord**'+JSON.stringify(this.qt));
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
}