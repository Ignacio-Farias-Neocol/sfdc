import { LightningElement, wire, track, api } from 'lwc';

//Import utilities
import { stringSort, numberSort, dateSort } from 'c/utilityModule';

/**
 * Container component that loads and displays a list of Serial__c records.
 */
export default class SerialTileList extends LightningElement {

  //Serials provided by parent
  @api
  get serials(){}
  set serials(value){
    if(value!=undefined){
      this.buildSerialsCollection(value);
      if(this.serialSubMap && !this._subsValueSet){
        this.populateSubs(this.serialSubMap);
      }
    } else{
      this.serialListData.length = 0;
      //Show empty state image
      this.showEmptyState = true;
      //Publish the event with null so that Subscription component returns nothing
      this.publishEvent(null);
    }
  }

  //Account type to determine if this is customer or partner.
  @api
  get accountType() {
    return this._accountType;
  }
  set accountType(value) {
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
    this._serialSubMap = value;
    if(this.serialListData && this.serialListData.length > 0){
      this.populateSubs(value);
    }
  }

  //Contains user or account id based on the accounttype
  @api entityId;

  //Local variable for serialSubMap. This is needed since setter for Serials is dependent on serialSubMap which is another api attribute. 
  _serialSubMap;

  //Determines if sub value was set or not
  _subsValueSet = false;

  //Local Account type value
  _accountType; 

  //Variable to determine the which tile should be shown
  external = true;

  //Card Title
  get cardTitle(){
    let numberOfSerials;
      if(this.serialListData){
        numberOfSerials = this.serialListData.length;
      }
      else{
        numberOfSerials = 0;
      }
      return "Serials (" + numberOfSerials + ")";
    }

  //List of serials
  @track serialListData = [];

  //Show empty data image
  @track showEmptyState = false;  
  // 0054D000001XS0PQAW

  //Boolean flags indicating which sort direction to be shown to user
  showStatusAscending = true;
  showExpDateAscending = true;

 
  buildSerialsCollection(data){
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
                                //Added as a part of SFDC-16035: START
                                customer360: data[i].customer360,
                                //Added as a part of SFDC-16035: END
                                subs: this._serialSubMap && this._serialSubMap.length > 0 ? this._serialSubMap[data[i].id] : undefined});
    }
    
    if(this.serialListData.length>0){
      //If there are items in the array then mark the first item as selected and publish the event
      this.serialListData[0].selected = true;

      //Publish the selection to get related subs
      this.publishEvent(this.serialListData[0]);

      //Hide Empty State image
      this.showEmptyState = false;      
    }
    else{
      //Show empty state image
      this.showEmptyState = true;

      //Publish the event with null so that Subscription component returns nothing
      this.publishEvent(null);
    }
  }

  //Handler when the Serial is Selected
  serialSelectionHandler(event) {
    //Get the selected Serial ID
    const serialId = event.detail;

    //Set Serial Selected = true for the selected serial and false for others
    //This changes the border color around the card
    this.serialListData.forEach(serial => {
      if(serial.id === serialId){
        serial.selected = true;
      }
      else{
        serial.selected = false;
      }
    });

    //Publish the selection
    this.publishEvent(this.serialListData.find(serial => serial.id === serialId));
  }

  //Handler for button menu
  handleMenuSelect(event) {
    // retrieve the selected item's value
    const selectedItemValue = event.detail.value;

    switch (selectedItemValue){
      case 'statusASC':
        //Sort Serials by Status in Ascending order
        numberSort(this.serialListData, 'statusNumber', 'ASC');
        this.showStatusAscending = false;  
        break;
      case 'statusDESC':
        //Sort Serials by Status in Descending order
        numberSort(this.serialListData, 'statusNumber', 'DESC');
        this.showStatusAscending = true;
        break;
      case 'expDateASC':
        //Sort Serials by Expiration Date in Ascending order
        dateSort(this.serialListData, 'contractEndDate', 'ASC');
        this.showExpDateAscending = false;
        break;
      case 'expDateDESC':
        //Sort Serials by Expiration Date in Descending order
        dateSort(this.serialListData, 'contractEndDate', 'DESC');
        this.showExpDateAscending = true;
        break;
      default:
        console.log('Menu Item Selected: ' + selectedItemValue);
    }



    // INSERT YOUR CODE HERE
  }
  //Function to publish the Serial Selection to parent component
  publishEvent(selectedSerial){
    //Raise an event
    // 1. Create an event
    const publishSerialEvent = new CustomEvent("publishserial", { detail: selectedSerial });

    console.log("Serial Select event published");
    // 2. Fire the custom event
    this.dispatchEvent(publishSerialEvent);   
  }

  //This function is used for internal version only. This populates the subs for serials
  populateSubs(data){
    this.serialListData.forEach(serial => serial.subs = data[serial.id]);
  }
}