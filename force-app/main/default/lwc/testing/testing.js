import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCases from '@salesforce/apex/MultipleCasesWithSameSerialController.getFilteredCases';
import NAME_FIELD from '@salesforce/schema/Account.Name';

const columns = [
  {label: 'Case Number', fieldName: 'URL', type: 'url', typeAttributes: { label: {fieldName: 'CaseNumber'}, target: '_self'}},
  { label: 'Case Record Type', fieldName: 'RecordTypeName', type: 'text' },
  { label: 'Opened Date', fieldName: 'Open_Date_time_Formatted__c', type: 'text' },
  { label: 'Owner', fieldName: 'Case_Owner_Person__c', type: 'text' },
  { label: 'Subject', fieldName: 'Subject', type: 'text' },
  { label: 'Account', fieldName: 'Account_Name__c', type: 'text' },
  { label: 'Contact', fieldName: 'Contact_Name__c', type: 'text' },
];

export default class Testing extends NavigationMixin(LightningElement) {
  @api cases;
  allCases;

  columns = columns;
connectedCallback() {
  this.allCases=this.cases?.map((result,index)=>{
        return {...result,URL:'/'+result.Id};
  });
}
  
  handleRowAction(event) {
    const caseId = event.detail.row.Id;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: caseId,
        actionName: 'view'
      }
    });
  }
}