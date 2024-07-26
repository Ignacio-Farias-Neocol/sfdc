import { LightningElement,api, track } from 'lwc';

//Column for Serial Table
const TABLECOLUMNS = [
  { label: 'Serial Number', fieldName: 'serialNumber' },
  { label: 'Error Message', fieldName: 'message'}
];

export default class FailedSerialsTable extends LightningElement {
  columns = TABLECOLUMNS;
  @api 
  get failedSerialsString(){}
  set failedSerialsString(value){
    if(value){
      this.failedSerials = JSON.parse(value);
    }
  }

  //Local variable tied to the table
  @track failedSerials;
}