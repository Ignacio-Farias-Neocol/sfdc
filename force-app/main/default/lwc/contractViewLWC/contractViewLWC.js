/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 09-14-2020
 * @last modified by  : 
 * Modifications Log 
 * 
**/
import { LightningElement ,api, wire, track} from 'lwc';
import getContractList from '@salesforce/apex/ContractViewCon.getContractList';
import prepareSerialReport from '@salesforce/apex/ContractViewCon.prepareSerialReport';
export default class ContractViewLWC extends LightningElement {

    @track openModal = false;
    showModal() {
        this.openModal = true;
    }
    closeModal() {
        this.openModal = false;
    }


    connectedCallback() {
        //window.addEventListener('resize', this.onResize);
    }

    @track error;
    @track contractWrapperList ;
    @track showModalButton;
    @track acceptanceCheckbox;
    @track isLoaded = false;
    @api contactId;
    @wire(getContractList)
    wiredAccounts({
        error,
        data
    }) {
        this.isLoaded = true;
        console.log('data:',data);
        console.log('error:',error);
        if (data) {
            this.contractWrapperList = data;
            console.log( data[0]);
            this.showModalButton = data[0].showDownloadReportButton;
        } else if (error) {
            this.error = error;
        }
        //this.onResize();
    }

    accept(){
        if(this.acceptanceCheckbox){
            console.log('List Passed: '+ JSON.stringify(this.contractWrapperList));
        prepareSerialReport({contractWrapperJSONStringify : JSON.stringify(this.contractWrapperList)}).then((result)=>{
            console.log('success');
            console.log('@@@@'+result);
            let downloadElement = document.createElement('a');
            downloadElement.href = 'data:text/csv;charset=utf-8,' +encodeURIComponent(result);
            downloadElement.target = '_self';
            downloadElement.download = 'SerialExpiryReport.csv';
            document.body.appendChild(downloadElement);
            downloadElement.click();
        }).catch((error)=> {
            console.log('error'+JSON.stringify(error));
        });
    }else{
        console.log('no');
    }
    }

    handleCheckBoxChange(event){
        this.acceptanceCheckbox = event.target.checked;
    }
    /* onResize = () => {
        let availHeight  = this.template.querySelector(`[data-id="customarea"]`).clientHeight - this.template.querySelector(`[data-id="header-part"]`).clientHeight;
        this.datatablestyle = 'height:'+(availHeight).toString()+'px';
    } */
}