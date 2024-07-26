import { LightningElement, track, api, wire } from "lwc";

//Import utilities
import { stringSort, numberSort, dateSort } from "c/utilityModule";

//Import custom labels
import noSubsToDisplay from '@salesforce/label/c.g_NoSubscriptionToDisplay';
import endUserName from '@salesforce/label/c.g_SubscriptionList_EndUserName_Label';
import sku from '@salesforce/label/c.g_SubscriptionList_SKU_Label';
import subscriptionDescription from '@salesforce/label/c.g_SubscriptionList_SubscriptionDescription_Label';
import startDate from '@salesforce/label/c.g_SubscriptionList_StartDate_Label';
import endDate from '@salesforce/label/c.g_SubscriptionList_EndDate_Label';
import quantity from '@salesforce/label/c.g_SubscriptionList_Quantity_Label';
import lastPurchaseOrderNumber from '@salesforce/label/c.g_SubscriptionList_LastPurchaseOrderNumber_Label';
import subscriptionStatus from '@salesforce/label/c.g_SubscriptionList_SubscriptionStatus_Label';
import eolStatus from '@salesforce/label/c.g_SubscriptionList_EOLStatus_Label';
import distributor from '@salesforce/label/c.g_SubscriptionList_Distributor_Label';
import reseller from '@salesforce/label/c.g_SubscriptionList_Reseller_Label';
import resellerLevel from '@salesforce/label/c.g_SubscriptionList_Reseller_Level_Label';
import productName from '@salesforce/label/c.g_SubscriptionList_ProductName_Label';
//import coreLicenseUsage from '@salesforce/label/c.g_SubscriptionList_Core_License_Usage_Label'; // Aditya - Added as part of SFDC-18330
import contract from '@salesforce/label/c.g_SubscriptionList_Contract_Label';
import annotationReason from '@salesforce/label/c.g_SubscriptionList_AnnotationReason_Label';
import statusNumber from '@salesforce/label/c.g_SubscriptionList_StatusNumber_Label';
import productSubscription from '@salesforce/label/c.g_SubscriptionList_ProductSubscription_Label';
//SFDC-17202: Added below line for the new column label "List Unit Price": START
import listUnitPrice from '@salesforce/label/c.g_SubscriptionList_ListUnitPrice_Label';
//SFDC-17202: Added below line for the new column label "List Unit Price": END
import extListPrice from '@salesforce/label/c.g_SubscriptionList_ExtListPrice_Label';
import totalListDisc from '@salesforce/label/c.g_SubscriptionList_TotalListDisc_Label';
import extFinalPrice from '@salesforce/label/c.g_SubscriptionList_ExtFinalPrice_Label';
import resellerAccountName from '@salesforce/label/c.g_SubscriptionList_ResellerAccountName_Label';
import resellerAccountType from '@salesforce/label/c.g_SubscriptionList_ResellerAccountType_Label';
import firstValueStatus from '@salesforce/label/c.g_SubscriptionList_FirstValueStatus_Label';//Added as part of SFDC-20028

const SUBSCRIPTION_COLUMNS_PARTNER = [
  {
    type: "text",
    fieldName: "endUserName",
    label: endUserName,
    wrapText: true,
    sortable: true
  },
  {
    type: "text",
    fieldName: "SKU",
    label: sku,
    wrapText: true,
    sortable: true
  },
  {
    type: "text",
    fieldName: "productName",
    label: productName,
    wrapText: true,
    sortable: true
  },
  {
    type: "date-local",
    fieldName: "subStartDate",
    label: startDate,
    sortable: true,
    typeAttributes: {
      month: "short",
      day: "2-digit",
      year: "numeric"
    }
  },
  {
    type: "date-local",
    fieldName: "subEndDate",
    label: endDate,
    sortable: true,
    typeAttributes: {
      month: "short",
      day: "2-digit",
      year: "numeric"
    }
  },
  {
    type: "number",
    fieldName: "quantity",
    label: quantity,
    sortable: true,
    cellAttributes: { alignment: "left" }
  },
  {
    type: "text",
    fieldName: "lastPurchaseOrderNumber",
    label: lastPurchaseOrderNumber,
    wrapText: true,
    sortable: true
  },
  {
    type: "iconCustomType",
    fieldName: "statusNumber",
    label: subscriptionStatus,
    sortable: true,
    typeAttributes: {
      iconName: { fieldName: "statusIcon" },
      iconSize: "small",
      iconVariant: { fieldName: "statusIconVariant" },
      iconTitle: { fieldName: "statusIconTitle" }
    }
  },
  {
    type: "boolean",
    fieldName: "autoRenewal",
    label: 'Auto Renewal',
    sortable: false,
    cellAttributes: {
      class: 'slds-align_absolute-center'
    }
  },
  {
    type: "text",
    fieldName: "reseller",
    label: reseller,
    wrapText: true,
    sortable: true
  },
  {
    type: "text",
    fieldName: "resellerLevel",
    label: resellerLevel,
    wrapText: true,
    sortable: true
  },
  {
    type: "iconCustomType",
    fieldName: "endOfLifeStatus",
    label: eolStatus,
    sortable: true,
    typeAttributes: {
      iconName: { fieldName: "eolStatusIcon" },
      iconSize: "small",
      iconVariant: { fieldName: "eolStatusIconVariant" },
      iconTitle: { fieldName: "eolStatusIconTitle" }
    }
  }
];

const SUBSCRIPTION_COLUMNS_CUSTOMER = [
  {
    type: "text",
    fieldName: "SKU",
    label: sku,
    wrapText: true,
    sortable: true
  },
  {
    type: "text",
    fieldName: "productName",
    label: productName,
    wrapText: true,
    sortable: true
  },
  {
    type: "date-local",
    fieldName: "subStartDate",
    label: startDate,
    sortable: true,
    typeAttributes: {
      month: "short",
      day: "2-digit",
      year: "numeric"
    }
  },
  {
    type: "date-local",
    fieldName: "subEndDate",
    label: endDate,
    sortable: true,
    typeAttributes: {
      month: "short",
      day: "2-digit",
      year: "numeric"
    }
  },
  {
    type: "number",
    fieldName: "quantity",
    label: quantity,
    sortable: true,
    cellAttributes: { alignment: "left" }
  },
  {
    type: "iconCustomType",
    fieldName: "statusNumber",
    label: subscriptionStatus,
    sortable: true,
    typeAttributes: {
      iconName: { fieldName: "statusIcon" },
      iconSize: "small",
      iconVariant: { fieldName: "statusIconVariant" },
      iconTitle: { fieldName: "statusIconTitle" }
    }
  },
  {
    type: "iconCustomType",
    fieldName: "endOfLifeStatus",
    label: eolStatus,
    sortable: true,
    typeAttributes: {
      iconName: { fieldName: "eolStatusIcon" },
      iconSize: "small",
      iconVariant: { fieldName: "eolStatusIconVariant" },
      iconTitle: { fieldName: "eolStatusIconTitle" }
    }
  },
  {
    type: "text",
    fieldName: "reseller",
    label: reseller,
    wrapText: true,
    sortable: true
  }
];

const SUBSCRIPTION_COLUMNS_INTERNAL = [
  {
    type: "text",
    fieldName: "productName",
    label: productName,
    wrapText: true,
    initialWidth: 300,
    sortable: true
  },
  // Aditya - Added coreLicenseUsage as part of SFDC-18330
  /*{
    type: "text",
    fieldName: "coreLicenseUsage",
    label: coreLicenseUsage,
    wrapText: true,
    initialWidth: 300,
    sortable: true
  },*/
  {
    type: "number",
    fieldName: "quantity",
    label: quantity,
    sortable: true,
    initialWidth: 75,
    cellAttributes: { alignment: "left" }
  },
  {
    fieldName: "subStartDate",
    label: startDate,
    sortable: true,
    type: "date-local",
    initialWidth: 120,
    typeAttributes: {
      month: "short",
      day: "2-digit",
      year: "numeric"
    }
  },
  {
    type: "date-local",
    fieldName: "subEndDate",
    label: endDate,
    sortable: true,
    initialWidth: 120,
    typeAttributes: {
      month: "short",
      day: "2-digit",
      year: "numeric"
    }
  },
  {
    type: "url",
    fieldName: "contractLink",
    label: contract,
    wrapText: true,
    sortable: true,
    initialWidth: 150,
    typeAttributes: {
      label: { fieldName: "contractNumber" },
      target: "_blank",
      tooltip: { fieldName: "contractNumber" }
    }
    
  },
  {
    type: "text",
    fieldName: "AnnotationReason",
    label: annotationReason,
    wrapText: true,
    initialWidth: 250,
    sortable: true
  },
  {
    type: "iconCustomType",
    fieldName: "statusNumber",
    label: statusNumber,
    sortable: true,
    initialWidth: 100,
    typeAttributes: {
      iconName: { fieldName: "statusIcon" },
      iconSize: "small",
      iconVariant: { fieldName: "statusIconVariant" },
      iconTitle: { fieldName: "statusIconTitle" }
    }
  },
  //Added FirstValueStatus as part of SFDC-20028
 {
    type: "text",
    fieldName: "firstValueStatus",
    label: firstValueStatus,
    wrapText: true,
    initialWidth: 150,
    sortable: true
  }
];

const QUOTE_COLUMNS = [
  {
    type: "text",
    fieldName: "endUserName",
    label: endUserName,
    wrapText: true,
    sortable: true
  },
  {
    type: "text",
    fieldName: "resellerAccountName",
    label: resellerAccountName,
    wrapText: true,
    sortable: true
  },
  //SFDC-17202: Remove the column, resellerAccountType: START
  /*{
    type: "text",
    fieldName: "resellerAccountType",
    label: resellerAccountType,
    wrapText: true,
    sortable: true
  },*/
  //SFDC-17202: Remove the column, resellerAccountType: END
  {
    type: "text",
    fieldName: "SKU",
    label: sku,
    wrapText: true,
    sortable: true
  },
  {
    type: "text",
    fieldName: "productSubscription",
    label: productSubscription,
    wrapText: true,
    sortable: true
  },
  //SFDC-17202: Added a new column as listUnitPrice: START
  {
    type: "currency",
    fieldName: "listUnitPrice",
    label: listUnitPrice,
    wrapText: true,
    sortable: true,
    typeAttributes: { currencyCode: { fieldName: 'currencyIsoCode' }, currencyDisplayAs: "code" }  // Aditya : Added as part of currency code
  },
  //SFDC-17202: Added a new column as listUnitPrice: END
  //SFDC-17202: Reordered the column, Quantity: START
  //Commenting the below out:
  /*{
    type: "text",
    fieldName: "quantity",
    label: quantity,
    wrapText: true,
    sortable: true
  },*/
   //SFDC-17202: Reordered the column, Quantity: START
  {
    type: "date-local",
    fieldName: "startDate",
    label: startDate,
    wrapText: true,
    sortable: true
  },
  {
    type: "date-local",
    fieldName: "endDate",
    label: endDate,
    wrapText: true,
    sortable: true
  },
  //SFDC-17202: Reordered the column, Quantity: START
  {
    type: "text",
    fieldName: "quantity",
    label: quantity,
    wrapText: true,
    sortable: true
  },
  //SFDC-17202: Reordered the column, Quantity: END
  {
    type: "currency",
    fieldName: "extListPrice",
    label: extListPrice,
    wrapText: true,
    sortable: true,
    typeAttributes: { currencyCode: { fieldName: 'currencyIsoCode' }, currencyDisplayAs: "code" }  // Aditya : Added as part of currency code
  },
  {
    type: "percent",
    fieldName: "totalListDisc",
    label: totalListDisc,
    wrapText: true,
    sortable: true,
    typeAttributes: { maximumFractionDigits: '2' },
  },
  {
    type: "currency",
    fieldName: "extFinalPrice",
    label: extFinalPrice,
    wrapText: true,
    sortable: true,
    cellAttributes: { alignment: 'right'},
    typeAttributes: { currencyCode: { fieldName: 'currencyIsoCode' }, currencyDisplayAs: "code" }  // Aditya : Added as part of currency code
  }
];

export default class SubscriptionList extends LightningElement {

  @api isReadOnly

  //Serial to be provided to get the list of subscriptions
  @api serial

  //Flag to set internal external
  @api isExternal = false;

  //Subscriptions sent by parent component
  @api subscriptions;
  //Account type
  @api accountType;

  connectedCallback() {
    console.log('The account type is: ' + this.accountType);
    if(this.isReadOnly) {
      this.isExternal = true;
    }
    this.setColumns();
    this.setSpinnerVisiblity();
    this.updateSubsCollection(this.subscriptions);
    console.log(this.columns);
    console.log('Column length: ' + this.columns.length);
  }
  
  label = {
    noSubsToDisplay
  };

  //local variable for serial
  _serial;

  //Local Variable for account type
  // _accountType;

  //Determines loading spinner visibility
  spinnerVisibility = true;

  //Card Title
  get cardTitle() {
    return "Subscriptions for Serial # " + this.serial.serialNumber;
  }
  
  //Changes card border based on selection
  get boxCSSClass() {
    return "slds-box slds-box_xx-small";
  }

  //Value tied to the data table
  @track subListData = [];

  // definition of columns for the table
  @track columns;

  //Table column sort properties
  @track defaultSortDirection = "asc";
  @track sortDirection = "asc";
  @track sortedBy;

  setColumns() {
    console.log('setting the column');
    console.log('isReadOnly...'+this.isReadOnly);
    console.log('accountType...'+this.accountType);
    if(this.isReadOnly) {
      this.columns = QUOTE_COLUMNS;
    } else {
      if (this.accountType === "Internal") {
        this.columns = SUBSCRIPTION_COLUMNS_INTERNAL;
        console.log('this.columns...'+this.columns);
      } else {
        if (this.accountType === "Reseller") {
          this.columns = SUBSCRIPTION_COLUMNS_PARTNER;
        } else {
          this.columns = SUBSCRIPTION_COLUMNS_CUSTOMER;
        }
      }
    }
  }

  setSpinnerVisiblity() {
    console.log('setting the spinner');
    if(this.subscriptions !== undefined) {
      this.spinnerVisibility = false;
    }
  }

  //Function to prepare the list for table
  updateSubsCollection(subs) {
    console.log('setting the subs collection');
    let _tempSubListData = [];
    //Empty the array before adding values
    if (this.subListData) {
      this.subListData.length = 0;
    }
    console.log(`isReadOnly1: ${this.isReadOnly}`);
    // console.log('Number of subs: ' + subs.length);
    // var subs = new Array();
    if(subs) {
      for (let i = 0; i < subs.length; i++) {
        var subRow = {};
        console.log(`isReadOnly2: ${this.isReadOnly}`);
        if(this.isReadOnly) {
          subRow.endUserName = subs[i].endUserName;
          subRow.SKU = subs[i].SKU;
          subRow.productSubscription = subs[i].product;
          /**
           * SFDC-17202: Added for the new column, "List Unit Price".
           * ********** reordered the column Quantity as recommended.
           * ********** Removed the column "resellerAccountType" as recommended.
           * ********* START
           */
          subRow.listUnitPrice = subs[i].listUnitPrice;
          subRow.startDate = subs[i].startDate;
          subRow.endDate = subs[i].endDate;
          subRow.quantity = subs[i].quantity;
          subRow.extListPrice = subs[i].extListPrice;
          subRow.totalListDisc = subs[i].totalListDisc;
          subRow.extFinalPrice = subs[i].extFinalPrice;
          //subRow.resellerAccountType = subs[i].resellerAccountType;
          /**
           * SFDC-17202: Added for the new column, "List Unit Price".
           * ********** reordered the column Quantity as recommended.
           * ********** Removed the column "resellerAccountType" as recommended.
           * ********* START
           */
          subRow.resellerAccountName = subs[i].resellerAccountName;
          subRow.currencyIsoCode = subs[i].currencyIsoCode; // Aditya : Added as part of currency code
          console.log('Populated sub columns');
        } else {
          subRow.SKU = subs[i].SKU;
          subRow.endUserName = subs[i].endUserName;
          subRow.lastPurchaseOrderNumber = subs[i].lastPurchaseOrderNumber;
          subRow.distrbutor = subs[i].distrbutor;
          subRow.endOfLifeStatus = subs[i].lifeCycleStatus;
          subRow.reseller = subs[i].reseller;
          subRow.resellerLevel = subs[i].resellerLevel;
          subRow.opportunityId = subs[i].opportunityId;
          subRow.quoteId = subs[i].quoteId;
          subRow.productName = subs[i].productName;
          //subRow.coreLicenseUsage = subs[i].coreLicenseUsage; // Aditya - Added as part of SFDC-18330
          subRow.quantity = subs[i].quantity;
          subRow.subStartDate = subs[i].subStartDate;
          subRow.subEndDate = subs[i].subEndDate;
          subRow.status = subs[i].status;
          subRow.statusNumber = subs[i].statusNumber;
          subRow.statusIcon = subs[i].iconDetail.statusIcon;
          subRow.statusIconAltText = subs[i].iconDetail.statusIconAltText;
          subRow.statusIconVariant = subs[i].iconDetail.statusIconVariant;
          subRow.statusIconTitle = subs[i].iconDetail.statusIconTitle;
          subRow.contractNumber = subs[i].contractNumber;
          subRow.AnnotationReason = subs[i].AnnotationReason;
          subRow.contractLink = "/" + subs[i].contractId;
          subRow.subscriptionDescription = subs[i].subscriptionDescription;
          subRow.autoRenewal = subs[i].autoRenewal;
          subRow.firstValueStatus = subs[i].firstValueStatus;


          if(subRow.endOfLifeStatus == 3) {
            subRow.eolStatusIcon = subs[i].lifeCycleStatusIcon.statusIcon;
            subRow.eolStatusIconAltText = subs[i].lifeCycleStatusIcon.statusIconAltText;
            subRow.eolStatusIconVariant = subs[i].lifeCycleStatusIcon.statusIconVariant;
            subRow.eolStatusIconTitle = subs[i].lifeCycleStatusIcon.statusIconTitle;
          }
        }

        _tempSubListData.push(subRow);
        console.log('SubListData '+ _tempSubListData.toString());
      }
    }
    //This is needed for the table to re-render
    this.subListData = _tempSubListData;

    //Sort the data if sortedby is not undefined
    if (this.sortedBy) {
      this.sortData(this.sortedBy, this.sortDirection);
    }
  }

  //Function to handle column sorting
  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    this.sortData(sortedBy, sortDirection);
  }

  //Function to sort data
  sortData(sortedBy, sortDirection) {
    const cloneData = [...this.subListData];

    if (sortedBy === "productName") {
      stringSort(cloneData, sortedBy, sortDirection);
    } else if (sortedBy === "quantity" || sortedBy === "statusNumber") {
      numberSort(cloneData, sortedBy, sortDirection);
    } else if (sortedBy === "subStartDate" || sortedBy === "subEndDate") {
      dateSort(cloneData, sortedBy, sortDirection);
    }
    this.subListData = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }
}