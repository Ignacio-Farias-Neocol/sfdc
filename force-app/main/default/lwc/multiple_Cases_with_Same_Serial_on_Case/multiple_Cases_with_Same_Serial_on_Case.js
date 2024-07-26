import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getFilteredCases from '@salesforce/apex/MultipleCasesWithSameSerialController.getFilteredCases';

const FIELDS = [
  'Case.Serial_Number__c',
  'Case.Pick_Product_only_if_Essentials__c'
];

export default class MultipleCasesWithSameSerialOnCase extends LightningElement {
  @api recordId;
  visibleCases = [];
  allCases = [];
  showViewAllButton = false;
  isModalOpen = false;
  serialNumber;
  pickProduct;
  caseCounts=0;
  noSimilarCases=false;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  retrieveCaseRecord({ error, data }) {
    if (data) {
      const caseObject = data.fields;
      this.serialNumber = caseObject.Serial_Number__c.value;
      this.pickProduct = caseObject.Pick_Product_only_if_Essentials__c.value;
      this.loadFilteredCases();
    } else if (error) {
      console.error(error);
    }
  }

  loadFilteredCases() {
    getFilteredCases({
      serialNumber: this.serialNumber,
      pickProduct: this.pickProduct
    })
      .then((result) => {
        this.allCases = result;
        this.frameRecordTypes(result);
        this.caseCounts=this.allCases.length;
        if(result){
        this.visibleCases = result.slice(0, 2);
        if(result.length > 2){
          this.showViewAllButton = true;
        }else if(result.length == 0){
          this.showViewAllButton = false;
        }
        if(result.length > 2){
          this.noSimilarCases = true;
        }else if(result.length == 0){
          this.noSimilarCases = false;
        }
        }
      })
      .catch((error) => {
       console.error(error);;
       });
  }

  frameRecordTypes(caseList){
    let totalCases = [];
    caseList.forEach((element) => {
      let newArray =[];
      newArray = element;
      newArray['RecordTypeName'] = element.RecordType.Name;
      totalCases = totalCases.concat(newArray);
    })
    this.allCases = totalCases;    
  }

  handleCaseClick(event) {
    const caseId = event.target.dataset.caseId;
    window.open('/' + caseId);
  }

  openModal() {
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
  }

  //get isThirdCase() {
  //  return (index) => index === 2;
  //}

  //get isLessThanLimit() {
  //  return (index) => index < 3;
  //}
}