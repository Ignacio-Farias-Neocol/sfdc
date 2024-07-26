import { LightningElement, api, track } from 'lwc';
import findAccounts from '@salesforce/apex/SerialMoveHelper.findAccounts';

import {FlowAttributeChangeEvent} from 'lightning/flowSupport';

const RESULT_LIMIT = 25;

export default class AccountSearch extends LightningElement {
  //Search key to be sent to Apex Class method
  searchKey = '';

  //List of accounts sent by Apex
  accounts;

  //Output parameter for the flow. Contains select Account info.
  @api targetPartnerAccount;

  @api
  validate() {
      if(this.targetPartnerAccount) { 
          return { isValid: true }; 
      } 
      else { 
          // If the component is invalid, return the isValid parameter 
          // as false and return an error message. 
          return { 
              isValid: false, 
              errorMessage: 'Select an Account before proceeding to next step.' 
          }; 
      }
  }

  //Used for radio buttons
  @track radiobuttonOptions = [];

  //Variable determining visibility of radio buttons
  @track showRadioButton = false;

  //Variable determining visibility of radio buttons
  @track showMessage = false;

  //Variable determining visibility of radio buttons
  @track message = ""; 
  
  //Variable for Spinner
  @track showSpinner = false;
  
  //Old Search Key
  _oldSearchKey;

  //Selected Item in the radiobutton
  selectedValue='';

  //Error during fetch
  error;

  //Keeps track of the value entered by the user
  handleKeyChange(event) {
    this.searchKey = event.target.value;
  }

  //calls apex method to execute search
  handleSearch() {
    if(this.searchKey!= this._oldSearchKey){
      //Show Spinner
      this.showSpinner = true;

      //Reset radio button options and accounts and selected partner account
      this.radiobuttonOptions.length = 0;
      this.accounts = undefined;
      this.targetPartnerAccount = undefined;
      this.showRadioButton = false;
      this.showMessage = false;
      this.message = "";
      this.selectedValue = "";

      //Call Apex
      findAccounts({ searchKey: this.searchKey,
                     resultLimit: RESULT_LIMIT })
        .then((result) => {
          //Set old searchkey
          this._oldSearchKey = this.searchKey;

          //If Apex sends a value
          if(result && result.length > 0){
          //Determine the length to be used for the loop
          let loopLength = result.length >= RESULT_LIMIT ? RESULT_LIMIT : result.length;
          //Populate radiobutton options. The label is name + username
          for(let i=0; i< loopLength ; i++){
          this.radiobuttonOptions.push({label: result[i].Name + " ( " + result[i].User_na__c + " )", 
          value: result[i].Id});
          }
          //Show radio buttons
          this.showRadioButton = true;

          //Get all accounts
          this.accounts = result; 
          this.error = undefined;       
          }
          if(this.radiobuttonOptions.length == 0){
          this.showMessage = true;
          this.message = "Your search did not return any results.";
          }
          else if(this.accounts && this.accounts.length > RESULT_LIMIT){
          this.showMessage = true;
          this.message = "Search returned more than " + RESULT_LIMIT + " records. Showing first " + RESULT_LIMIT + " rows." + " Refine your search criteria."
          }
          else{
          this.showMessage = false;
          this.message = "";
          } 

          //Hide Spinner
          this.showSpinner = false;

          }
        )
        .catch((error) => {
        this.error = error;
        this.radiobuttonOptions.length = 0;
        this.accounts = undefined;
        this.showRadioButton = false;
        this.showMessage = true;
        this.message = "Your search did not return any results." + this.error.message;
        //Hide Spinner
        this.showSpinner = false;
        });  
    }

      
  }

  handleRadioButtonSelection(event){
    this.selectedValue = event.detail.value;
    this.targetPartnerAccount = this.accounts ? this.accounts.find(element => element.Id == this.selectedValue):undefined;
    this.dispatchEvent(new FlowAttributeChangeEvent('targetPartnerAccount', this.targetPartnerAccount));
  }
}