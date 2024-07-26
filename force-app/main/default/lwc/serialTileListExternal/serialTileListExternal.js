import { LightningElement, track, api } from 'lwc';

//Import utilities
import { stringSort, numberSort, dateSort } from 'c/utilityModule';

//Import custom labels
import noSubsToDisplay from '@salesforce/label/c.g_NoSubscriptionToDisplay';
import sortStatus from '@salesforce/label/c.g_SortStatus';
import sortExpirationDate from '@salesforce/label/c.g_SortExpirationDate';
/**
 * Container component that loads and displays a list of Serial__c records.
 */
export default class SerialTileListExternal extends LightningElement {

  //flag for read only. Default to false and set to true when called from renewal checkout flow
  @api isReadOnly = false;

  @api paginationDetails = {};

  //Serials provided by parent
  @api
  get serials(){}
  set serials(value){
    console.log('In serials setter');
    if(value!=undefined){
      // this.buildSerialsCollection(value);
      this.serialListData = value.map(element => ({...element}));
      this.getTotal();
      this.showEmptyState = false;
    } else{
      this.serialListData.length = 0;
      //Show empty state image
      this.showEmptyState = true;
    }
  }

  //Account type to determine if this is customer or partner.
  @api
  get accountType() {
    return this._accountType;
  }
  set accountType(value) {
    console.log('AccountType: ' + value);
    if (value) {
      this.external =
        value === "Internal"
          ? false
          : true;
      this._accountType = value;
    } else {
      this.external = true;
    }
  }

  //Data passed from parent containing subscriptions for serials
  @api 
  get serialSubMap(){
    return this._serialSubMap;
  }

  set serialSubMap(value){
    if(!this._serialSubMap) {
      this._serialSubMap = value;
      if(this.serialListData && this.serialListData.length > 0){
        this.populateSubs(value);
      }
    }
  }

  //Contains user or account id based on the accounttype
  @api entityId;

  label = {
    noSubsToDisplay,
    sortStatus,
    sortExpirationDate
  };

  //Local variable for serialSubMap. This is needed since setter for Serials is dependent on serialSubMap which is another api attribute. 
  _serialSubMap;

  //Determines if sub value was set or not
  _subsValueSet = false;

  //Local Account type value
  _accountType; 

  //Variable to determine the which tile should be shown
  external = true;

  currencyCode;// = 'USD';

  renderedCallback() {
    if(this.serialListData.length > 0) {
      this.showEmptyState = false;
    } else {
      this.showEmptyState = true;
    }
  }

  //Card Title
  get cardTitle(){
    if(this.isReadOnly) {
      return "";
    } else {
      return "Displaying (" + this.paginationDetails.recordStart + " - " + this.paginationDetails.recordEnd + ") of " + this.paginationDetails.totalSerialRecords + " Serials Found";
    }
  }

  get subTitle(){
    let subTitleString = "Across " + this.paginationDetails.serialRecordCount + ' Serial';

    subTitleString += this.paginationDetails.serailRecordCount > 1 ? 's' : '';
    return subTitleString;
  }

  // Card Title Icon
  get cardTitleIcon(){
    if(this.isReadOnly) {
      return "";
    } else {
      return "custom:custom46";
    }
  }

  get showTotal() {
    if(this.isReadOnly && !this.showEmptyState) {
      return true;
    } else {
      return false;
    }
  }

  //List of serials
  @track serialListData = [];

  //Show empty data image
  @track showEmptyState = false;  
  // 0054D000001XS0PQAW

  //Boolean flags indicating which sort direction to be shown to user
  showStatusAscending = true;
  showExpDateAscending = true;

  total;

 
  buildSerialsCollection(data){
    console.log('Building serials collections');
    //Empty the array before adding values
    if(this.serialListData && this.serialListData.length>0){
      this.serialListData.length = 0
    }
      
    //Prepare the serials array
    for(let i=0; i< data.length; i++){
      this.serialListData.push({baseProductSKU: data[i].baseProductSKU,
                                contractEndDate:data[i].contractEndDate,
                                id:data[i].id,
                                partner: data[i].partner,
                                productName: data[i].productName, 
                                quantity: data[i].quantity,
                                serialNumber: data[i].serialNumber,
                                status: data[i].status,
                                statusNumber: data[i].statusNumber,
                                iconDetail: data[i].iconDetail,       
                                selected: false,
                                businessGroup: data[i].businessGroup,
                                quoteId: data[i].quoteId,
                                quoteName: data[i].quoteName,
                                renewalOppId: data[i].renewalOppId,
                                accountId: data[i].accountId,
                                accountName: data[i].accountName,
                                isBillToAccount: data[i].isBillToAccount,
                                hasOpenCase: data[i].hasOpenCase,
                                // subs: this._serialSubMap && this._serialSubMap.length > 0 ? this._serialSubMap[data[i].id] : undefined});
                                subs: data[i].subs});
    }
    // dateSort(this.serialListData, 'contractEndDate', 'ASC');
    console.log('serialListData.length: ' + this.serialListData.length);
  }

  getTotal() {
    let total = 0.0;
    console.log('Serial Data: ' + JSON.stringify(this.serialListData));
    if(this.serialListData) {
      for(let i=0; i<this.serialListData.length;i++) {
        let currentSerial = this.serialListData[i];
        if(currentSerial.subs) {
          for(let j=0; j<currentSerial.subs.length; j++) {
            console.log('Sub Data: ' + JSON.stringify(currentSerial.subs[j]));
            console.log('type value: ' + typeof currentSerial.subs[j].extFinalPrice);
            total += currentSerial.subs[j].extFinalPrice;
            this.currencyCode = currentSerial.subs[j].currencyIsoCode;
          }
        }
      }
    }
    console.log('currencyCode...'+this.currencyCode);
    this.total = total;
  }

  //Handler when the Serial is Selected
  serialSelectionHandler(event) {
   // Don't do anything for this handler
  }

  //Handler for 'renewserial' event
  handleRenewSerial(event) {
    this.template.querySelector('c-serial-confirmation-modal').confirmModal(
      event.detail.requiresConfirmation,
      event.detail.quoteId,
      event.detail.serialId
    );
  }

  //Handler for 'showmodification' event
  handleShowModificationRequest(event) {
    //placeholder call
    console.log('in event handler');
    this.template.querySelector('c-modification-request-modal').showModalPopup(
      event.detail.opportunityId,
      event.detail.accountId,
      event.detail.accountName,
      event.detail.quoteName
    );
  }

  handlerequestcreated(event) {
    for(let i =0; i < this.serialListData.length; i++) {
      if(this.serialListData[i].renewalOppId == event.detail.parentOppId) {
        console.log('serial found: ' + this.serialListData[i].hasOpenCase);
        this.serialListData[i] = {...this.serialListData[i], hasOpenCase:true}
        console.log('serial updated: ' + this.serialListData[i].hasOpenCase);
        this.template.querySelector('c-serial-tile[data-id="' + this.serialListData[i].id + '"]').disableRenewal();    
      }
    }
    
    //Create an event
    const filterEvent = new CustomEvent("requestcreated", {
        detail: {parentOppId: event.detail.parentOppId}
    });

    //Raise an event
    this.dispatchEvent(filterEvent);
  }

  //This function is used for internal version only. This populates the subs for serials
  populateSubs(data){
    // console.log('populating subs with data: ' + JSON.stringify(data));
    this.serialListData.forEach(serial => serial.subs = data[serial.id]);
    this.getTotal();
  }
}