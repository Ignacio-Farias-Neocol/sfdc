/**
 * JS file to support the Serial Move Wizard.
 * Update: SFDC-12989 - Add an interim logic to allow uplevel to same product code. This will be removed after SFDC-12959 is deployed to Production.
 */
import { LightningElement, api, track, wire } from "lwc";
import updateAssignedSerials from "@salesforce/apex/SerialMoveHelper.updateAssignedSerials";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getProdCatRecords from "@salesforce/apex/SerialMoveHelper.getProdCatRecords";
import getExceptionpCodes from "@salesforce/apex/SerialMoveHelper.getExceptionpCodes";

import {
  FlowNavigationNextEvent,
  FlowNavigationBackEvent,
  FlowNavigationFinishEvent,
  FlowAttributeChangeEvent,
} from "lightning/flowSupport";

//Used to determine the icon for serial tile
const iconMap = new Map([
  ["success", { iconName: "utility:success", variant: "Success" }],
  ["warning", { iconName: "utility:warning", variant: "warning" }],
  ["error", { iconName: "utility:error", variant: "error" }],
]);

const MAPPING_SCREEN_CLASS = "slds-show slds-scrollable_y scroll-height";

//Column for Serial Table
const TABLECOLUMNS = [
  {
    type: "serialCardCustomType",
    fieldName: "id",
    label: "Serials",
    hideDefaultActions: true,
    typeAttributes: {
      serial: { fieldName: "serial" },
    },
  },
];

//Confirmation Screen options
const radiobuttonOptions = [
  { label: "Yes, submit the request to move serials", value: "submit" },
  { label: "No, exit the process", value: "exit" },
];

export default class SerialMoveDialog extends LightningElement {
  columns = TABLECOLUMNS;

  @api serialpCat;
  @api subpCat;
  @api exceptionpCodes;
  @api exceptionpCodesArray;
  @track pCode;

  //Variable for Spinner
  @track showSpinner = false;

  //Determines serial move type. Passed by the flow
  @api moveType;

  //Salesforce update message after apex call
  @api sfUpdateMessage;

  //Salesforce update result after apex call
  @api sfUpdateResult;

  //Variable used to exit process
  @api sfExitProcess;

  //Variable to control class associated with the mapping screen
  mappingScreenClass = MAPPING_SCREEN_CLASS;

  //Variable controlling visibility of the type of footer
  showMappingFooter = true;

  //Variable to control class associated with the confirmation screen
  confirmationScreenClass = "slds-hide";

  //List of serials fetched for an SMB. Passed by the flow
  @api
  get serialList() {
    return this.serialListDataOriginal;
  }
  set serialList(value) {
    if (value != undefined) {
      //Keep a copy of data returned by the api
      this.serialListDataOriginal = value;

      //Build the collection for table
      this.serialListData = this.buildSerialsCollection(value);
    } else {
      //Reset table
      this.serialListData.length = 0;
    }
  }

  //List of serials to passed to the data table
  @track serialListData = [];

  //Local variable to store original serial values
  serialListDataOriginal;

  //List of target Subscriptions fetched for a partner account. Passed by the flow
  @api
  get subscriptionList() {}
  set subscriptionList(value) {
    if (value != undefined) {
      this.buildSubscriptionsCollection(value);
    } else {
      this.subscriptionListData.length = 0;
      // this.serialListData = [...this.serialListData];
    }
  }

  //List of Subscriptions to be passed to Subscriptions list
  @track subscriptionListData = [];

  //SMB username. Passed by the flow
  @api smbUsername;

  //Target partner user name. Passed by the flow
  @api partnerUsername;

  //JSON to be sent to the API. Passed back to the flow
  @api
  get serialMoveJSON() {
    return JSON.stringify(this.subscriptionListData);
  }
  set serialMoveJSON(value) {}

  //Variable to toggle disabled property of confirmation footer button
  buttonDisabled = false;

  //Confirmation Screen Properties
  radiobuttonOptions = radiobuttonOptions;
  selectedValue = "";

  //Build Serial COllection for the table
  buildSerialsCollection(data) {
    console.log("Data used to build table collection: " + JSON.stringify(data));

    //Empty the array before adding values
    // if(this.serialListData && this.serialListData.length>0){
    //   this.serialListData.length = 0
    // }
    let tempSerials = [];
    //Prepare the serials array
    for (let i = 0; i < data.length; i++) {
      //Prepare icon details
      let iconDetail = {
        statusIconAltText: data[i].Serial__r.Status__c,
        statusIconTitle: data[i].Serial__r.Status__c,
      };

      //Determine icon name and variant
      if (data[i].Serial__r.Status__c === "Active") {
        iconDetail.statusIcon = iconMap.get("success").iconName;
        iconDetail.statusIconVariant = iconMap.get("success").variant;
      } else if (data[i].Serial__r.Status__c === "Inactive") {
        iconDetail.statusIcon = iconMap.get("error").iconName;
        iconDetail.statusIconVariant = iconMap.get("error").variant;
      } else if (data[i].Serial__r.Status__c === "Pending Termination") {
        iconDetail.statusIcon = iconMap.get("warning").iconName;
        iconDetail.statusIconVariant = iconMap.get("warning").variant;
      }

      //Serial Object
      let serial = {
        serialNumber: data[i].Serial_Number__c,
        serialid: data[i].Serial__c,
        smbName: data[i].SMB_Name__c,
        basesku: data[i].Serial__r.Base_Product_SKU__c,
        status: data[i].Serial__r.Status__c,
        capacity: data[i].Capacity__c ? data[i].Capacity__c : 0,
        subscription: {
          name: data[i].Subscription__r.Name,
          id: data[i].Subscription__r.Id,
          productName: data[i].Subscription__r.SBQQ__ProductName__c,
          productCode: data[i].Subscription__r.Product_Code__c,
          echoIdentifier:
            data[i].Subscription__r.ECHO_Unique_Identifier_Value__c,
        },
        iconDetail: iconDetail,
      };

      tempSerials.push({ id: data[i].Id, serial: serial });
    }

    return tempSerials;
  }

  //Build Subsscription Collection for the list
  buildSubscriptionsCollection(data) {
    console.log(
      "Subscription Data used to build Sub table collection " +
        JSON.stringify(data)
    );
    //Empty the array before adding values
    if (this.subscriptionListData && this.subscriptionListData.length > 0) {
      this.subscriptionListData.length = 0;
    }

    //Prepare the serials array
    for (let i = 0; i < data.length; i++) {
      //Serial Object
      let subscription = {
        subscriptionId: data[i].Id,
        subscriptionProductName: data[i].SBQQ__ProductName__c,
        subscriptionProductCode: data[i].Product_Code__c,
        subscriptionOrderId: data[i].Universal_Order_Id__c,
        subscriptionOrderLineId: data[i].Universal_OrderItem_Id__c,
        subscriptionRootId: data[i].SBQQ__RootId__c,
        subscriptionContract: data[i].SBQQ__Contract__c,
        subscriptionEchoId: data[i].ECHO_Unique_Identifier_Value__c,
      };

      this.subscriptionListData.push(subscription);
    }
  }

  async setSubCatValues(event, selectedSerials) {
    console.log("Sub Start");
    const result = await getProdCatRecords({
      pCode: event.detail.subscriptionProductCode,
    });
    this.subpCat = result;
    console.log(this.subpCat);
    console.log("Sub End");

    await this.setSerialCatValue(selectedSerials);
  }

  async setSerialCatValue(selectedSerials) {
    for (const cs of selectedSerials) {
      console.log("Serial Start");
      const result1 = await getProdCatRecords({
        pCode: cs.serial.subscription.productCode,
      });
      this.serialpCat = result1;
      console.log(this.serialpCat);
      console.log("Serial End");
    }
  }

  async getExceptionpCodes() {
    const result = await getExceptionpCodes();
    this.exceptionpCodes = result;
    console.log("Serial Start::" + this.exceptionpCodes);
    this.exceptionpCodesArray =
      this.exceptionpCodes != null ? this.exceptionpCodes.split(",") : "";
    console.log("pArray::" + this.exceptionpCodesArray);

    // if(this.exceptionpCodesArray.indexOf("BEO-AES1-MSP") !== -1){

    //   console.log('BEO-AES1-MSP found');
    // }
    // else {

    //   console.log('BEO-AES1-MSP Not found');
    // }
  }

  //Handles the event raised by map serials button
  async handleMapSerials(event) {
    //Get Selected Serials
    let selectedSerials = this.template
      .querySelector("c-custom-datatable")
      .getSelectedRows();
    if (selectedSerials && selectedSerials.length > 0) {
      /*Loop through the selected serials and add selected serials as per the following rule
       1. For migration the Product code should be same as the target subscription
       2. For uplevel the Product code should not be the same as the target subscription. (Note that there is no validation to prevent downgrading)
       3. INTERIM fix added as part of SFDC-12989: For upleve the Product Code can be the same as the target subscription*/
      //Allowed Serials
      let allowedSerials = [];
      //Rejected Serials
      let rejectedSerials = [];

      await this.setSubCatValues(event, selectedSerials);

      await this.getExceptionpCodes();

      selectedSerials.forEach((currentSerial) => {
        //Check if product code matches. This is done only for migration.
        /** BLOCK COMMENTED FOR SFDC-12989. TO REMOVE THIS FIX AFTER SFDC-12959 IS DEPLOYED UNCOMMENT THIS BLOCK
        // if((this.moveType === "Migration" &&  
        //    currentSerial.serial.subscription.productCode === event.detail.subscriptionProductCode) || 
        //    (this.moveType === "Uplevel" && currentSerial.serial.subscription.productCode !== event.detail.subscriptionProductCode)){
        //   allowedSerials.push(currentSerial);
        // } */
        // BELOW BLOCK ADDED FOR SFDC-12989. TO REMOVE THIS FIX AFTER SFDC-12959 IS DEPLOYED DELETE THIS BLOCK

        console.log("moveType:: " + this.moveType);
        console.log(
          " currentSerial.serial.subscription.productCode:: " +
            currentSerial.serial.subscription.productCode
        ); //BEO-IMP1-MSP
        console.log(
          " event.detail.subscriptionProductCode:: " +
            event.detail.subscriptionProductCode
        ); //BEO-AES1-MSP

        if (
          (this.moveType === "Migration" &&
            currentSerial.serial.subscription.productCode ===
              event.detail.subscriptionProductCode) ||
          (this.moveType === "Uplevel" &&
            this.serialpCat === "Old" &&
            this.subpCat === "Old") ||
          (this.serialpCat === "Old" && this.subpCat === "New") ||
          (this.serialpCat === "New" && this.subpCat === "New") ||
          this.exceptionpCodesArray.indexOf(
            event.detail.subscriptionProductCode
          ) !== -1 ||
          this.exceptionpCodesArray.indexOf(
            currentSerial.serial.subscription.productCode
          ) !== -1
        ) {
          allowedSerials.push(currentSerial);
          console.log("allowedSerials:: " + allowedSerials);
        }
        // ABOVE BLOCK ADDED FOR SFDC-12989. TO REMOVE THIS FIX AFTER SFDC-12959 IS DEPLOYED DELETE THIS BLOCK
        else {
          rejectedSerials.push(currentSerial);
        }
      });

      if (allowedSerials && allowedSerials.length > 0) {
        //Add serial to target sub
        //Clone the Subscription list
        let tempSubList = [...this.subscriptionListData];

        //Find the sub that raised the event
        const sub = tempSubList.find(
          (element) => element.subscriptionId == event.detail.subscriptionId
        );

        //If there are serials in subs already then concatenate. Else assign.
        if (sub.serials) {
          sub.serials = sub.serials.concat(allowedSerials);
        } else {
          sub.serials = allowedSerials;
        }

        //Update table data
        this.subscriptionListData = [...tempSubList];

        //Remove Serial from the Serial List
        this.removeSerialsFromSource(allowedSerials);

        console.log(
          "handleMapSerials subscriptionListData::" +
            JSON.stringify(this.subscriptionListData)
        );
      }

      if (rejectedSerials && rejectedSerials.length > 0) {
        //Prepare the message
        let message = "Serial # ";

        //Get comma separated list of serials that were not added
        rejectedSerials.forEach((element) => {
          message += element.serial.serialNumber + ",";
        });

        //Remove the last comma
        message = message.replace(/,\s*$/, "") + " cannot be moved.";
        // message += this.moveType === "Migration" ? "Serial product code and target Subscription product code should match." : "Serial product code and target Subscription product code should not be the same.";
        message +=
          this.moveType === "Migration"
            ? "Serial product code and target Subscription product code should match."
            : " Moving New Bundle to Old Bundle Not Permitted.";

        // alert(message);
        //Show toast
        this.showToast("Serial Move", message, "error");
      }
    } else {
      //Show a toast that Serials need to be selected for mapping
      // alert("Select a row before mapping");

      //Show toast
      this.showToast("Serial Move", "Select a row before mapping", "error");
    }
  }

  //This function removes serials from source table once they are mapped to a Subscription
  removeSerialsFromSource(selectedSerials) {
    //Copy the original source
    let duplicateSerials = [...this.serialListData];

    /* Loop through selected serials. 
       Call delete row method to remove the row from the table */
    selectedSerials.forEach((row) => {
      //Get the Id of the Serial being deleted
      let assignedSerialId = row.id;

      //Find the index of this Id in duplicateSerials
      const index = duplicateSerials.findIndex(
        (element) => element.id === assignedSerialId
      );

      if (index !== -1) {
        //Remove this element from duplicateSerials
        duplicateSerials = duplicateSerials
          .slice(0, index)
          .concat(duplicateSerials.slice(index + 1));
      }
    });

    console.log("Duplicate Serials - " + JSON.stringify(duplicateSerials));

    //Assign the value to datatable
    this.serialListData = [...duplicateSerials];
  }

  //Function to handle the event raised when a serial is removed from a target sub
  handleUnmapSerial(event) {
    //Prepare the list of assigned serials to be shown
    let assignedSerialIdList = [event.detail.serial.id];

    //loop through current table and get the remaining Ids
    this.serialListData.forEach((tableRow) => {
      assignedSerialIdList.push(tableRow.id);
    });

    //Loop through id list to get the serials in Original list.
    //Filter out other serials in the Original list
    //Call buildSerialsCollection() and pass this filtered list.
    //We are doing this to maintain the order in which these serials were originally presented
    let updatedSerialCollection = [];

    if (assignedSerialIdList && assignedSerialIdList.length > 0) {
      this.serialListDataOriginal.forEach((assignedSerial) => {
        if (assignedSerialIdList.some((id) => assignedSerial.Id === id)) {
          updatedSerialCollection.push(assignedSerial);
        }
      });

      if (updatedSerialCollection && updatedSerialCollection.length > 0) {
        this.serialListData = this.buildSerialsCollection(
          updatedSerialCollection
        );
      }

      //Remove Serials from Subscription list data
      //Clone the Subscription list
      let tempSubList = [...this.subscriptionListData];

      //Find the sub that raised the event
      const sub = tempSubList.find(
        (element) => element.subscriptionId == event.detail.subscriptionId
      );

      //Remove the serial from the serial list in this sub
      //Find the index of this Id in subscription serials
      const index = sub.serials.findIndex(
        (element) => element.id === event.detail.serial.id
      );

      if (index !== -1) {
        //Remove this element from serials
        sub.serials = sub.serials
          .slice(0, index)
          .concat(sub.serials.slice(index + 1));
      }

      //Update table data
      this.subscriptionListData = [...tempSubList];
    }
  }

  //Hander for radio buttons
  handleRadioButtonSelection(event) {
    this.selectedValue = event.detail.value;
  }

  //Handler for the previous button on mapping screen. Takes the user to previous screen
  handlePreviousForMapping() {
    this.goPrevious();
  }

  //Handler for the next button on mapping screen. Takes the user to confirmation screen
  handleSubmit() {
    if (
      this.moveType === "Uplevel" &&
      this.serialListData != null &&
      this.serialListData.length == this.serialListDataOriginal.length
    ) {
      //Show toast
      this.showToast(
        "Serial " + this.moveType,
        "Map serials before moving to the next step",
        "error"
      );
    } else if (
      this.moveType === "Migration" &&
      this.serialListData != null &&
      this.serialListData.length > 0
    ) {
      //Show toast
      this.showToast(
        "Serial Migration",
        "All Serials should be mapped before moving to the next step.",
        "error"
      );
    } else {
      this.mappingScreenClass = "slds-hide";
      this.confirmationScreenClass = "slds-show";
      this.showMappingFooter = false;
    }
  }

  //Handler for the previous button on confirmation screen. Takes the user to mapping screen
  handlePreviousForConfirmation() {
    //Reset the selected value
    this.selectedValue = "";
    this.mappingScreenClass = MAPPING_SCREEN_CLASS;
    this.confirmationScreenClass = "slds-hide";
    this.showMappingFooter = true;
  }

  //Handler for the next button on confirmation screen. Submits the request to salesforce and goes to next element in the flow
  handleConfirmation() {
    this.showSpinner = true;
    this.buttonDisabled = true;
    if (this.selectedValue === "submit") {
      //Call Apex class for Salesforce update
      updateAssignedSerials({ serialSubMapString: this.serialMoveJSON })
        .then((apexCallResult) => {
          //If Apex sends a value
          if (apexCallResult) {
            this.sfUpdateMessage = apexCallResult.message;
            this.sfUpdateResult = apexCallResult.result;
            console.log(
              "Result: " + this.sfUpdateMessage + " " + this.sfUpdateResult
            );
          }

          //Go to next element
          this.goNext();
        })
        .catch((error) => {
          this.sfUpdateMessage =
            "Error updating Assigned Serial in Salesforce. Since Salesforce update failed, request was not sent to ECHO" +
            error.message;
          this.sfUpdateResult = false;
          //Go to next element
          this.goNext();
        });
    } else if (this.selectedValue === "exit") {
      this.sfExitProcess = true;
      this.goNext();
    } else {
      this.showToast(
        "Error:",
        "Please choose an option before clicking Next button",
        "error"
      );
      this.showSpinner = false;
      this.buttonDisabled = false;
    }
  }

  //Go to previous element
  goPrevious() {
    const navigatePreviousEvent = new FlowNavigationBackEvent();
    this.dispatchEvent(navigatePreviousEvent);
  }

  //Go to next element
  goNext() {
    this.showSpinner = false;
    this.dispatchEvent(
      new FlowAttributeChangeEvent("sfUpdateMessage", this.sfUpdateMessage)
    );
    this.dispatchEvent(
      new FlowAttributeChangeEvent("sfUpdateResult", this.sfUpdateResult)
    );
    this.dispatchEvent(
      new FlowAttributeChangeEvent("sfExitProcess", this.sfExitProcess)
    );
    this.dispatchEvent(
      new FlowAttributeChangeEvent("serialMoveJSON", this.serialMoveJSON)
    );
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  //terminate flow
  terminateFlow() {
    const navigateFinishEvent = new FlowNavigationFinishEvent();
    this.dispatchEvent(navigateFinishEvent);
  }

  //Function to show toast
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(event);
  }
}