import { LightningElement, api, track } from 'lwc';

const TABLECOLUMNS = [
  {
    type: "text",
    fieldName: "serialNumber",
    label:"Serials",
    hideDefaultActions: true
  },
  {
    type: "button-icon",
    initialWidth: 75,
    typeAttributes:{
      iconName: "utility:delete",
      title: "Remove Serial",
      variant: "border-filled",
      alternativeText: "Remove Serial",
      name:"remove"
    }
  }
];

const TABLEDATA = [
  {
   id:"1",
   serialNumber:"699510",
  },
  {
    id:"2",
    serialNumber:"691960",
  }
];

export default class TargetSubscriptionCard extends LightningElement {
  @api 
  get sub(){
    return this.subData;
  }
  set sub(value){
    if(value!=undefined){
      this.subData = value;
      this.buildSerialsCollection(value);
    } else{
      this.subscriptionListData.length = 0;
    }    
  }

  @track subData;

  @api 
  get serials(){}
  set serials(value){
    if(value!=undefined){
      this.buildSerialsCollection(value);
    } else{
      this.serialListData.length = 0;
    }    
  }

  @track serialListData = [];

  columns = TABLECOLUMNS;

  //Determines the icon to be displayed in the button
  iconName = "utility:right";

  //Determines table visibility
  tableVisibility = "hide-table";

  //Button disability
  disableButton = true;

  //Build Serial COllection for the table
  buildSerialsCollection(data){
    console.log("Serial Data in Target: " + JSON.stringify(data));
    //Empty the array before adding values
    if(this.serialListData && this.serialListData.length>0){
      this.serialListData.length = 0
    }
    
    let tempSerials = [];
    if(data && data.length>0){
      //Prepare the serials array
      for(let i=0; i< data.length; i++){
        //Serial Object
        let serial = {
          serialNumber:data[i].serial.serialNumber, 
          id: data[i].id
        }
        
        tempSerials.push(serial);
      }
    }

    if(tempSerials.length>0){
      this.serialListData = [...tempSerials];
      this.disableButton = false;
      
    }
    else{
      this.serialListData.length = 0;
      this.disableButton = true;
      this.tableVisibility = "hide-table";
      this.disableButton = true;
      this.iconName = "utility:right";
    }
  }

  //Handler for Map Serials button
  mapSerialsToSubs(event){

    //Create an event to send Sub data. We are sending sub Id and Sub Product code
    const mapEvent = new CustomEvent("mapserials", {
      detail: {subscriptionId: this.subData.subscriptionId,
               subscriptionProductCode: this.subData.subscriptionProductCode}
    });
    // Fire the custom event
    this.dispatchEvent(mapEvent);
  }

  //Handler for the button
  showHideSerials(event){
    if(this.iconName === "utility:right"){
      this.iconName = "utility:down";
      this.tableVisibility = "show-table";
    }
    else{
      this.iconName = "utility:right";
      this.tableVisibility = "hide-table";
    }
  }

  handleRowAction(event){
    const row = event.detail.row;
    // this.deleteRow(row);
    if(this.serialListData == undefined || this.serialListData == null || this.serialListData.length==0){
      this.tableVisibility = "hide-table";
      this.disableButton = true;
      this.iconName = "utility:right";
    }
    //Publish an event for parent to put the serial back to Source serial table
    //Create an event to send Sub data. We are sending sub Id and Sub Product code
    const removeMappingEvent = new CustomEvent("unmapserial", {
      detail: {serial: row,
               subscriptionId: this.subData.subscriptionId}
    });
    // Fire the custom event
    this.dispatchEvent(removeMappingEvent);
  }

  // deleteRow(row) {
  //   const { id } = row;
  //   const index = this.findRowIndexById(id);
  //   if (index !== -1) {
  //     this.serialListData = this.serialListData
  //         .slice(0, index)
  //         .concat(this.serialListData.slice(index + 1));
  //   }
  // }  

  // findRowIndexById(id) {
  //   let ret = -1;
  //   this.serialListData.some((row, index) => {
  //     if (row.id === id) {
  //         ret = index;
  //         return true;
  //     }
  //     return false;
  //   });
  //   return ret;
  // }
}