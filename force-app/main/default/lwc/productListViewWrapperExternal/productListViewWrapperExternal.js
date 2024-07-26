import { LightningElement, wire, track, api } from "lwc";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from "@salesforce/user/Id";
import ACCOUNT_TYPE from '@salesforce/schema/User.Contact.Account.Type';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/** getSerialDetails() method in ProductListViewHelper Apex class */
import getSerialSubDetails from "@salesforce/apex/ProductListViewHelperExternal.getSerialSubDetails";

//Import custom labels
import noSubsToDisplay from '@salesforce/label/c.g_NoSubscriptionToDisplay';

const PAGE_LIMIT = 25;

export default class ProductListViewWrapperExternal extends LightningElement {
  
  userId = Id;

  @wire(getRecord, { recordId: '$userId', fields: [ACCOUNT_TYPE] })
  wiredUser({ error, data }) {
    console.log('gettin user data');
    if(data) {
      if(getFieldValue(data, ACCOUNT_TYPE).includes('Distributor')) {
        this.isDistributorAccount = true;
      }
      this.setDefaultDates();
    }
  }

    //Determines loading spinner visibility
  spinnerVisibility = true;
  spinnerText = 'Loading Serials. This process may take some time.';

  //Serial selected in the serialTileList component
  @track selectedSerial;

  //Show empty data image
  @track showEmptyState = true;

  /*Property to identify which type of account to use to fetch serial. 
  This determines the Account field for the query*/
  @api
  get accounttype() {
    return this._accountType;
  }

  set accounttype(value) {
    this._accountType = value;
    this.entityId = value === "Internal" ? this.recordId : this._userId; 
    this.external = value === "Internal" ? false : true;
  }

  isDistributorAccount = false;

  //Record ID
  @api recordId;
  
  label = {
    noSubsToDisplay
  };

  //Determines if we are in internal or external version
  external = true;

  // Full set of Serials for defined date range
  totalQueriedSerialsList = [];

  // Full set of Serials with all filters applied
  totalFilteredSerialsList = [];

  //Serials to be sent to child component
  serialsToDisplay;

  //Subscriptions for the selected Serial
  subscriptions;

  //Collection of Serials and Subs
  serialSubs;

  //Community user's ID
  _userId = Id;
  
  //Account type sent to Apex Call
  _accountType;

  //Entity ID
  entityId; 

  //Error when fetching serials
  error;

  paginationDetails = {
    totalSerialRecords: 0,
    totalSubscriptionRecords: 0,
    serialRecordCount: 0,
    recordStart: 0,
    recordEnd: 0,
    previousDisabled: false,
    nextDisabled: false
  };

  filters = {
    accountType: this._accountType,
    fromDate: '',
    toDate: '',
    serialString: '',
    endUserString: '',
    partnerString: '', //Aditya : added for distributor filter 
    statusFilter: [1, 2, 3],
    pageNumber: 1
  };

  pageOptions=[];

  setDefaultDates() {
    console.log('In connected callback');
    const lookBackRangePartner = 15;
    const lookForwardRangePartner = 30;

    const lookBackRangeDisti = 0;
    const lookForwardRangeDisti = 7;

    const lookBackRangeCustomer = 365;

    let today = new Date();
    
    if(this.accounttype == 'Customer') {
      this.filters.fromDate = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackRangeCustomer)));
    } else if(this.isDistributorAccount) {
      this.filters.fromDate = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackRangeDisti)));
      this.filters.toDate = this.formatDateVals(new Date(new Date().setDate(today.getDate() + lookForwardRangeDisti)));
    } else if(this.accounttype == 'Reseller'){
      this.filters.fromDate = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackRangePartner)));
      this.filters.toDate = this.formatDateVals(new Date(new Date().setDate(today.getDate() + lookForwardRangePartner)));
    } 

    this.getSerials();
  }

  get pageLimitOptions() {
    var pageLimitList = [
        { label: '10', value: '10' },
        { label: '15', value: '15' },
        { label: '20', value: '20' },
        { label: '50', value: '50' },
        { label: '100', value: '100' },
    ];
    return pageLimitList;
  }

  getSerials() {
    console.log(this.accounttype+' '+this.filters.fromDate+' '+this.filters.toDate);
    console.log(this.filters.partnerString+' '+this.filters.serialString+' '+this.filters.endUserString);
    this.spinnerVisibility = true;
    getSerialSubDetails({accountType: this.accounttype,
                         fromDate: this.filters.fromDate,
                         toDate: this.filters.toDate,
                         serialNumber: this.filters.serialString,
                         endUserString: this.filters.endUserString,
                         partnerString: this.filters.partnerString})
        .then(result => {
            console.log('In getSerials result'+JSON.stringify(result));
            if(result) {
              this.serialSubs = result;

              if (this.serialSubs.serials && this.serialSubs.serials.length > 0) {
                  this.totalQueriedSerialsList = this.serialSubs.serials.map(element => ({...element}));
                  this.applyClientSideFilters();
                  this.setPaginationDetails();
                  
                  this.showEmptyState = false;
              } else {
                  this.showEmptyState = true;
              }
              this.spinnerVisibility = false;

              this.error = undefined;
            } else {
              this.showEmptyState = true;
              this.spinnerVisibility = false;
              this.serials = undefined;
              this.serialSubs = undefined;
            }
        })
        .catch(error => {
          var exceptioMsg = error.body.message
          console.log('In error');
          console.log(error);
          console.log('ExceptionType-- '+error.body.exceptionType);
          console.log('ExceptionMessage-- '+exceptioMsg);
          console.log('ExistMessage-- '+exceptioMsg.indexOf('An internal server error has occurred'));
          this.showEmptyState = true;
          this.spinnerVisibility = false;
          this.error = error;
          this.serials = undefined;
          this.serialSubs = undefined;
          var errorMessage= 'There was an error when loading serials. Please try refreshing the page.';
          if(error.body.exceptionType == 'System.LimitException' || exceptioMsg.indexOf('An internal server error has occurred') != -1 ){
            errorMessage = 'The number of subscriptions for the given date range you have selected is high. Please narrow down your date range and try again.';
          }
          const event = new ShowToastEvent({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
            mode: 'sticky'
          });
          this.dispatchEvent(event);
      });
 }

  preparePaginationList() {
    let begin = (this.filters.pageNumber - 1) * PAGE_LIMIT;
    let end = parseInt(begin) + parseInt(PAGE_LIMIT);
    this.serialsToDisplay = this.totalFilteredSerialsList.slice(begin, end);
  }

  setPaginationDetails() {
    console.log('set pagination');
    this.preparePaginationList();
    this.paginationDetails.recordStart = (this.filters.pageNumber - 1) * PAGE_LIMIT + 1;
    this.paginationDetails.recordEnd = this.paginationDetails.recordStart + this.serialsToDisplay.length - 1;
    this.paginationDetails.serialRecordCount = this.totalFilteredSerialsList.length;
    this.paginationDetails.totalSerialRecords = this.totalFilteredSerialsList.length;
    this.paginationDetails.totalPages = Math.ceil(this.paginationDetails.totalSerialRecords / PAGE_LIMIT);

    if(this.filters.pageNumber == 1) {
      this.paginationDetails.previousDisabled = true;
    } else {
      this.paginationDetails.previousDisabled = false;
    }

    if(this.filters.pageNumber < this.paginationDetails.totalPages) {
      this.paginationDetails.nextDisabled = false;
    } else {
      this.paginationDetails.nextDisabled = true;
    }
    
    this.pageOptions = [];
    for(var i=1; i<= this.paginationDetails.totalPages; i++) {
        let pageOptObj={};
        pageOptObj.label=i.toString();
        pageOptObj.value=i;
        this.pageOptions.push(pageOptObj);
    }
  }

  handleFirst() {
    this.filters.pageNumber = 1;
    this.setPaginationDetails();
  }

  handlePrevious() {
    this.filters.pageNumber--;
    this.setPaginationDetails();
  }

  handleNext() {
    this.filters.pageNumber++;
    this.setPaginationDetails();
  }

  handleLast() {
    this.filters.pageNumber = this.paginationDetails.totalPages;
    this.setPaginationDetails();
  }

  handlePageChange(event) {
    this.filters.pageNumber = parseInt(event.target.value);
    this.setPaginationDetails();
  }

  //Event handler for the serial selection event
  getRelatedSubs(event) {
    this.selectedSerial = event.detail;
    if(this.selectedSerial){
      if (this.serialSubs && this.serialSubs.serialSubMap) {
        this.subscriptions = this.serialSubs.serialSubMap[this.selectedSerial.id];
      } else {
        this.subscriptions = undefined;
      }
    }
    else{
      this.subscriptions = undefined;
    }

    console.log("Serial selection event handled");
    // console.log("ACCT TYPE IN PLVWH: " + this.accounttype);
  }

  //Handler for the event fired from Search Component
  handleFilterChange(event) {
    console.log("Filtering started");
    console.log(JSON.stringify(this.filters));
    let queryForNewRecords = false;

    if(this.filters.fromDate != event.detail.dateFrom || this.filters.toDate != event.detail.dateTo){
      queryForNewRecords = true;
    }
    console.log('Event data: ' + JSON.stringify(event));
    console.log('Event data: ' + JSON.stringify(event.detail));
    this.filters.fromDate = event.detail.dateFrom;
    this.filters.toDate = event.detail.dateTo;
    this.filters.serialString = event.detail.searchSerialString;
    this.filters.endUserString = event.detail.searchEndUserString;
    this.filters.partnerString = event.detail.searchPartnerString;  //Aditya : added for distributor filter
    this.filters.statusFilter = event.detail.statusFilter;
    this.filters.pageNumber = 1;
    console.log('this.filters.fromDate..'+this.filters.fromDate);
    console.log('this.filters.toDate..'+this.filters.toDate);
    console.log('queryForNewRecords..'+queryForNewRecords);
    if(queryForNewRecords) {
      this.getSerials();
    } else {
      this.spinnerVisibility = true;
      this.applyClientSideFilters();
      this.setPaginationDetails();
      this.spinnerVisibility = false;
    }
  }

  applyClientSideFilters() {
    console.log('apply client side filters');
    this.totalFilteredSerialsList = this.totalQueriedSerialsList;
    console.log('data list: ' + JSON.stringify(this.totalFilteredSerialsList));
    if(this.filters.serialString){
      //Get serials based on the searchSerialString criteria
      this.totalFilteredSerialsList = this.filterSerialsBasedOnSerialNumber(
        this.totalFilteredSerialsList,
        this.filters.serialString
      );
    }
    
    if(this.filters.endUserString){
      //Get serials based on the searchEndUser criteria
      this.totalFilteredSerialsList = this.filterSerialsBasedOnEndUser(
        this.totalFilteredSerialsList,
        this.filters.endUserString
      );
    }

    //Aditya : added for distributor filter
    console.log('Reseller search val: ' + this.filters.partnerString);
    if(this.filters.partnerString){
      this.totalFilteredSerialsList = this.filterSerialsBasedOnPartner(
        this.totalFilteredSerialsList,
        this.filters.partnerString
      );
    }
    
    //Perform Status filter
    if (this.filters.statusFilter != null) {
      this.totalFilteredSerialsList = this.filterSerialsBasedOnValueList(
        this.totalFilteredSerialsList,
        "statusNumber",
        this.filters.statusFilter
      );
    }
    console.log("Filtering ended");
  }

  //Function to filter serial array based on searched SerialNumber
  filterSerialsBasedOnSerialNumber(arr, searchSerialNumber) {
    console.log('filter by serial');
    return arr.filter(function(serial) {
      if (serial.serialNumber && serial.serialNumber.toLowerCase().includes(searchSerialNumber.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    });
  }

  //Function to filter serial array based on searched EndUser
  filterSerialsBasedOnEndUser(arr, searchEndUserString) {
    console.log('filter by endUser');
    return arr.filter(function(serial) {
      if (serial.accountName && serial.accountName.toLowerCase().includes(searchEndUserString.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    });
  }

  //Aditya : added for distributor filter
  //Function to filter serial array based on searched Partner/Reseller
  filterSerialsBasedOnPartner(arr, searchPartnerString) {
    console.log('searchPartnerString...'+searchPartnerString);
    return arr.filter(function(serial) {
      if (serial.partner && serial.partner.toLowerCase().includes(searchPartnerString.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    });
  }

  //Function to filter serial array based on Date
  filterSerialsBasedOnDateRange(arr, dateFrom, dateTo) {
    console.log('filter by date');
    return arr.filter(function(serial) {
      if (dateFrom && dateTo) {
        return (
          serial.contractEndDate >= dateFrom && serial.contractEndDate <= dateTo
        );
      } else if (dateFrom && !dateTo) {
        return serial.contractEndDate >= dateFrom;
      } else if (!dateFrom && dateTo) {
        return serial.contractEndDate <= dateTo;
      } else {
        return false;
      }
    });
  }

  //Function to filter serial array based on list of values
  filterSerialsBasedOnValueList(arr, fieldName, filterValues) {
    console.log('filter by value');
    console.log('field Name: ' + fieldName);
    console.log('field values: ' + filterValues);
    return arr.filter(function(serial) {
      return filterValues.some(function(value) {
        console.log(serial);
        console.log(value);
        if (serial[fieldName] === value) {
          return true;
        } else {
          return false;
        }
      });
    });
  }

  formatDateVals(date) {
    return date.toISOString().split('T')[0];
  }

  handlerequestcreated(event) {
    for(let i =0; i < this.totalFilteredSerialsList.length; i++) {
      if(this.totalFilteredSerialsList[i].renewalOppId == event.detail.parentOppId) {
        console.log('serial found: ' + this.totalFilteredSerialsList[i].hasOpenCase);
        this.totalFilteredSerialsList[i].hasOpenCase = true;
        console.log('serial updated: ' + this.totalFilteredSerialsList[i].hasOpenCase);
      }
    }
  }
}