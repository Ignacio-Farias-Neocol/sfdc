import { LightningElement, api, wire } from "lwc";

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_TYPE from '@salesforce/schema/User.Contact.Account.Type';
import Id from '@salesforce/user/Id';

//Import custom labels
import resetButtonFilter from '@salesforce/label/c.g_SerialSubFilter_ResetFilterButton_Label';
import searchHeader from '@salesforce/label/c.g_SerialSubFilter_Search_Header';
import searchKeyLabel from '@salesforce/label/c.g_SerialSubFilter_SearchKey_Label';
import searchSerialLabel from '@salesforce/label/c.g_SerialSubFilter_SearchSerial_Label';
import searchEndUserLabel from '@salesforce/label/c.g_SerialSubFilter_SearchEndUser_Label';
import searchPartnerLabel from '@salesforce/label/c.g_SerialSubFilter_SearchPartner_Label';
import searchKeyHelpText from '@salesforce/label/c.g_SerialSubFilter_SearchKey_HelpText';
import searchSerialHelpText from '@salesforce/label/c.g_SerialSubFilter_SearchSerial_HelpText';
import searchEndUserHelpText from '@salesforce/label/c.g_SerialSubFilter_SearchEndUser_HelpText';
import searchPartnerHelpText from '@salesforce/label/c.g_SerialSubFilter_SearchPartner_HelpText';
import serialExpDateHeader from '@salesforce/label/c.g_SerialSubFilter_SerialExpirationDate_Header';
import dateFrom from '@salesforce/label/c.g_SerialSubFilter_DateFrom_Label';
import dateTo from '@salesforce/label/c.g_SerialSubFilter_DateTo_Label';
import serialStatusHeader from '@salesforce/label/c.g_SerialSubFilter_SerialStatus_Header';
import serialStatusActive from '@salesforce/label/c.g_SerialSubFilter_SerialStatusActive_Label';
import serialStatusUpcomingRenewal from '@salesforce/label/c.g_SerialSubFilter_SerialStatusUpcomingRenewal_Label';
import serialStatusExpiredReplacedReturned from '@salesforce/label/c.g_SerialSubFilter_SerialStatusExpiredReplacedReturned_Label';
import businessGroupHeader from '@salesforce/label/c.g_SerialSubFilter_BusinessGroup_Header';
import businessGroupCore from '@salesforce/label/c.g_SerialSubFilter_BusinessGroupCore_Label';
import businessGroupMSP from '@salesforce/label/c.g_SerialSubFilter_BusinessGroupMSP_Label';
import businessGroupSonian from '@salesforce/label/c.g_SerialSubFilter_BusinessGroupSonian_Label';
import businessGroupNone from '@salesforce/label/c.g_SerialSubFilter_BusinessGroupNone_Label';
import applyFilters from '@salesforce/label/c.g_Apply_Filters';

export default class SerialSubFilterExternal extends LightningElement {
  userId = Id;

  @wire(getRecord, { recordId: '$userId', fields: [ACCOUNT_TYPE] })
  wiredUser({ error, data }) {
    console.log('gettin user data');
    if(data) {
      if(getFieldValue(data, ACCOUNT_TYPE).includes('Distributor')) {
        this.showPartnerSearch = true;
        this.isDistributorAccount = true;
      }
      this.setDefaultDates();
    }
  }

  //Account type
  @api
  get accountType() {
    return this._accountType;
  }
  set accountType(value) {
    this._accountType = value;
    if (value === "Internal") {
      this.layoutItemSize = 3;
      this.showBusinessGroup = true;
      this.filters.businessGroupFilter = ["Core", "MSP", "Sonian", undefined];
      this.external = false;
      console.log("Account type in filter: " + value);
    } else {
      if( value === "Reseller"){
        this.showEndUserSearch = true;
      }
      let today = new Date();
      this.layoutItemSize = 4;
      this.showBusinessGroup = false;
      this.filters.businessGroupFilter = null;
      today.setFullYear( today.getFullYear() - 1 );
      this.startDateMinDate = this.formatDateVals(today);
    //   this.createAndPublishEvent();
    }
  }

  isDistributorAccount = false;

  label = {
    resetButtonFilter,
    searchHeader,
    searchKeyLabel,
    searchSerialLabel,
    searchEndUserLabel,
    searchPartnerLabel,
    searchKeyHelpText,
    searchSerialHelpText,
    searchEndUserHelpText,
    searchPartnerHelpText,
    serialExpDateHeader,
    dateFrom,
    dateTo,
    serialStatusHeader,
    serialStatusActive,
    serialStatusUpcomingRenewal,
    serialStatusExpiredReplacedReturned,
    businessGroupHeader,
    businessGroupCore,
    businessGroupMSP,
    businessGroupSonian,
    businessGroupNone,
    applyFilters
  }

  //Boolean flag to denote if a user is internal or external
  external = true;

  showEndUserSearch = false;

  showPartnerSearch = false;

  startDateMinDate;

  //Layout Item Size
  layoutItemSize = 4;

  //Flag to determine the visibility of business group filter
  showBusinessGroup;

  //Filter values
  searchKey ="";
  searchSerialString = "";
  searchEndUserString = "";
  searchPartnerString = "";
  dateFrom = "";
  dateTo = "";

  filters = {
    searchKey: this.searchKey,
    searchSerialString: this.searchSerialString,
    searchEndUserString: this.searchEndUserString,
    searchPartnerString: this.searchPartnerString,
    statusFilter: [1, 2, 3],
    dateFrom: this.dateFrom,
    dateTo: this.dateTo
  };

  //Local Variable for account type
  _accountType;

  // Default date search for external accountTypes
  setDefaultDates(){
    console.log('SETTING DEFAULT DATES');
    const lookBackRangePartner = 15;
    const lookForwardRangePartner = 30;

    const lookBackRangeDisti = 0;
    const lookForwardRangeDisti = 7;

    const lookBackRangeCustomer = 365;

    let today = new Date();
    
    if(this.accountType == 'Customer') {
      this.dateFrom = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackRangeCustomer)));
    } else if(this.isDistributorAccount) {
      this.dateFrom = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackRangeDisti)));
      this.dateTo = this.formatDateVals(new Date(new Date().setDate(today.getDate() + lookForwardRangeDisti)));
    } else if(this.accountType == 'Reseller'){
      this.dateFrom = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackRangePartner)));
      this.dateTo = this.formatDateVals(new Date(new Date().setDate(today.getDate() + lookForwardRangePartner)));
    }

    this.filters.dateFrom = this.dateFrom;
    this.filters.dateTo = this.dateTo;
  }

  formatDateVals(date) {
    return date.toISOString().split('T')[0];
  }

  //Event handler for the onchange event of search field
  handleSearchKeyChange(event) {
    this.searchKey = event.target.value;

    //Update filters object
    this.filters.searchKey = this.searchKey;
  }

  //Event handler for the onchange event of serial search field
  handleSerialKeyChange(event) {
    this.searchSerialString = event.target.value;

    //Update filters object
    this.filters.searchSerialString = this.searchSerialString;
  }

  //Event handler for the onchange event of end user search field
  handleEndUserKeyChange(event) {
    this.searchEndUserString = event.target.value;

    //Update filters object
    this.filters.searchEndUserString = this.searchEndUserString;
  }

  //Event handler for the onchange event of end user search field
  handlePartnerKeyChange(event) {
    this.searchPartnerString = event.target.value;

    //Update filters object
    this.filters.searchPartnerString = this.searchPartnerString;
  }

  //Event handler for the onchange event of date fields
  handleDateChange(event) {
    if (event.target.name === "dateFrom") {
      //Update filters object
      this.dateFrom = event.target.value;
      this.filters.dateFrom = event.target.value;
    } else if (event.target.name === "dateTo") {
      //Update filters object
      this.dateTo = event.target.value;
      this.filters.dateTo = event.target.value;
    }
  }

  handleStatusFilterChange(event) {
    const name = event.target.name;
    let value;
    switch (name) {
      case "cbActive":
        value = 1;
        break;
      case "cbRenew":
        value = 2;
        break;
      case "cbInactive":
        value = 3;
        break;
      default:
        value = "";
    }
    const filterArray = this.filters.statusFilter;

    if (event.target.checked) {
      if (!filterArray.includes(value)) {
        filterArray.push(value);
      }
    } else {
      this.filters.statusFilter = filterArray.filter((item) => item !== value);
    }
  }

  handleBusinessGroupFilterChange(event) {
    const name = event.target.name;
    let value;
    switch (name) {
      case "cbCore":
        value = "Core";
        break;
      case "cbMSP":
        value = "MSP";
        break;
      case "cbSonian":
        value = "Sonian";
        break;
      case "cbNoBG":
        value = undefined;
        break;
      default:
        value = "";
    }

    const filterArray = this.filters.businessGroupFilter;

    //Add the value if it is checked else remove it
    if (event.target.checked) {
      if (!filterArray.includes(value)) {
        filterArray.push(value);
      }
    } else {
      this.filters.businessGroupFilter = filterArray.filter(
        (item) => item !== value
      );
    }
  }

  //Function to handle reset filters button
  resetFilters() {
    //Set searchKey searchSerialString and searchEndUser to blank
    this.searchKey=""
    this.searchSerialString = "";
    this.searchEndUserString = "";
    this.searchPartnerString = "";

    this.filters.searchKey = this.searchKey;
    this.filters.searchSerialString = this.searchSerialString;
    this.filters.searchEndUserString = this.searchEndUserString;
    this.filters.searchPartnerString = this.searchPartnerString;

    //Set dates to default, blank if external and 15 back 30 forward if internal

    if(this.external){
      this.setDefaultDates();
    } else {
      this.dateTo = "";
      this.filters.dateTo = "";
      this.dateFrom = "";
      this.filters.dateFrom = "";
    }

    //Set status to checked
    this.template.querySelectorAll(".statusCB").forEach((cb) => {
      cb.checked = true;
    });

    //Set the statusFilter
    this.filters.statusFilter = [1, 2, 3];

    //Set Business Group to checked
    this.template.querySelectorAll(".businessGroupCB").forEach((cb) => {
      cb.checked = true;
    });

    //Set the businessGroupFilter
    if (this._accountType === "Internal") {
      this.filters.businessGroupFilter = ["Core", "MSP", "Sonian", undefined];
    } else {
      this.filters.businessGroupFilter = null;
    }

    this.createAndPublishEvent();
  }

  //Function to handle applying filters
  applyFilters() {
    //Fire the event
    this.createAndPublishEvent();
  }

  //Function to create and publish event to parent component
  createAndPublishEvent() {
    //Create an event
    const filterEvent = new CustomEvent("filterchange", {
      detail: this.filters
    });

    //Raise an event
    this.dispatchEvent(filterEvent);
  }
}