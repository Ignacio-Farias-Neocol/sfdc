import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ACCOUNT_TYPE from '@salesforce/schema/User.Contact.Account.Type';
import Id from '@salesforce/user/Id';

//Import utilities
import { stringSort, numberSort, dateSort } from "c/utilityModule";

import getOrders from "@salesforce/apex/OrderListViewHelper.getOrders";
import getUrl from "@salesforce/apex/ProductListViewHelper.getUrl";

//Import custom labels
import serialNumbers from '@salesforce/label/c.g_Serial_Numbers';
import resetButtonFilter from '@salesforce/label/c.g_SerialSubFilter_ResetFilterButton_Label';
import filtersHeader from '@salesforce/label/c.g_My_Order_Page_Filters';
import ordersHeader from '@salesforce/label/c.g_My_Order_Page_Orders';
import billToContactLabel from '@salesforce/label/c.g_My_Order_Page_Bill_To_Contact';
import fulfillmentDateLabel from '@salesforce/label/c.g_My_Order_Page_Fulfillment_Date';
import amountLabel from '@salesforce/label/c.g_My_Order_Page_Order_Amount';
import orderDateLabel from '@salesforce/label/c.g_my_Order_Page_Order_Date';
import orderNumberLabel from '@salesforce/label/c.g_My_Order_Page_Order_Number';
import partnerLabel from '@salesforce/label/c.g_My_Order_Page_Partner';
import poNumberLabel from '@salesforce/label/c.g_RenewalCheckout_PurchaseOrderNumber';
import quoteNumberLabel from '@salesforce/label/c.g_My_Order_Page_Quote_Number';
import endUserLabel from '@salesforce/label/c.g_My_Order_Page_End_User';
import applyFilters from '@salesforce/label/c.g_Apply_Filters';
import subCertificate from '@salesforce/label/c.g_My_Order_Page_Sub_Certificater';

/** The delay used when debouncing event handlers before firing the event. */
const DELAY = 350;
/**The default date range for date filters*/
const LOOK_BACK_DAY_RANGE = 30;
const LOOK_FORWARD_DAY_RANGE = 0;
const LOOK_BACK_MONTH_RANGE = 15;
const QUERY_LIMIT = 'Too many query rows: 50001';

const PAGE_LIMIT = 25;

export default class OrderListView extends LightningElement {

  orderColumns = [
    {
      type: "date-local",
      fieldName: "orderDate",
      label: orderDateLabel,
      sortable: true,
      typeAttributes: {
        month: "short",
        day: "2-digit",
        year: "numeric"
      }
    },
    {
      type: "date-local",
      fieldName: "fulfillmentDate",
      label: fulfillmentDateLabel,
      sortable: true,
      typeAttributes: {
        month: "short",
        day: "2-digit",
        year: "numeric"
      }
    },
    {
      type: "text",
      fieldName: "orderNumber",
      label: orderNumberLabel,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "poNumber",
      label: poNumberLabel,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "quoteNumber",
      label: quoteNumberLabel,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "serialNumbers",
      label: serialNumbers,
      wrapText: true,
      sortable: true
    },
    {
      type: "currency",
      fieldName: "orderAmount",
      label: amountLabel,
      wrapText: true,
      sortable: true,
      typeAttributes: { currencyCode: this.currencyCode}
    },
    {
      type: "text",
      fieldName: "billToContact",
      label: billToContactLabel,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "partner",
      label: partnerLabel,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "endUser",
      label: endUserLabel,
      wrapText: true,
      sortable: true
    },
    {
      type: "button",
      fieldName: "url",
      label: subCertificate,
      typeAttributes: {
          variant: 'base',
          name: 'download',
          iconName : 'utility:work_order_type',
          iconPosition : 'right'
      }
    }
  ];

  userId = Id;

  @wire(getRecord, { recordId: '$userId', fields: [ACCOUNT_TYPE] })
  wiredUser({ error, data }) {
    console.log('gettin user data');
    if(data) {
      if(getFieldValue(data, ACCOUNT_TYPE).includes('Distributor')) {
        this.showResellerSearch = true;
      }
    }
  }

  @api 
  get accounttype() {}

  set accounttype(value) {
    if(value){
      this._accountType = value;
      if(value == 'Customer') {
        this.showSerialNumberSearch = true;
      } else if (value == 'Reseller') {
        this.showSerialNumberSearch = true;
        this.showEndUserSearch = true;
      } 
    }
  }

  //Community user's ID
  _userId = Id;
  _accountType;

  formatDateVals(date) {
    return date.toISOString().split('T')[0];
  }

  labels = {
    resetButtonFilter,
    applyFilters,
    filtersHeader,
    ordersHeader,
    orderDateLabel,
    noOrdersToDisplay: 'No Orders to Display'
  };

  paginationDetails = {
    totalOrderRecords: 0,
    orderRecordCount: 0,
    recordStart: 0,
    recordEnd: 0,
    previousDisabled: false,
    nextDisabled: false
  };

  pageOptions=[];

  pageNumber = 1;

  searchSerialNumberString = '';
  searchEndUserString = '';
  searchResellerString = '';

  fromDateFilter = '';
  toDateFilter = '';
  fromDateDefault = '';
  toDateDefault = '';
  minFromDate = '';
  maxToDate = '';

  serialNumberSearchLabel = 'Serial Number';
  endUserSearchLabel = 'End User';
  resellerSearchLabel = 'Reseller';

  showSerialNumberSearch = false;
  showEndUserSearch = false;
  showResellerSearch = false;

  allData = [];
  filteredData = [];
  ordersToDisplay = [];

  columns = this.orderColumns;

  currencyCode = 'USD';

  //Table column sort properties
  defaultSortDirection = "desc";
  sortDirection = "desc";
  sortedBy = 'orderDate';

  showEmptyState = true;
  spinnerVisibility = false;
  errorMessage = '';

  connectedCallback() {
    console.log('In connected callback');

    var today = new Date();

    this.fromDateDefault = this.formatDateVals(new Date(new Date().setDate(today.getDate() - LOOK_BACK_DAY_RANGE)));
    this.toDateDefault = this.formatDateVals(new Date(new Date().setDate(today.getDate() + LOOK_FORWARD_DAY_RANGE)));
    this.minFromDate = this.formatDateVals(new Date(new Date().setMonth(today.getMonth() - LOOK_BACK_MONTH_RANGE)));
    this.maxToDate = '';

    this.fromDateFilter = this.fromDateDefault;
    this.toDateFilter = this.toDateDefault;

    this.getOrders();
  }

  getOrders() {
    console.log('Getting Orders');
    this.spinnerVisibility = true;
    getOrders({userId: this._userId,
                         fromDate: this.fromDateFilter,
                         toDate: this.toDateFilter})
      .then(result => {
        console.log('Retrieved Orders data.');
        this.allData = result;
        console.log('this.allDat..'+JSON.stringify(this.allData));
        this.pageNumber = 1;
        this.applyFilters();
        this.spinnerVisibility = false;
      })
      .catch(error => {
        console.log('error...' + JSON.stringify(error));
        let message = error.body.message;
        if(message != QUERY_LIMIT) {
          this.errorMessage = 'Something went wrong';
        } else {
          this.errorMessage = 'Too many Orders found. Please refine your search and try again.';
        }
        this.showToastErrorEvent();
      });
  }

  resetFilters() {
    this.template.querySelector('c-text-search-filter').reset();
    this.template.querySelector('c-date-search-filter').reset();
    this.searchSerialNumberString = '';
    this.searchEndUserString = '';
    this.searchResellerString = '';
    this.fromDateFilter = this.fromDateDefault;
    this.toDateFilter = this.toDateDefault;
    this.getOrders();
  }

  ontextsearchchange(event) {
    this.searchSerialNumberString = event.detail.searchTextString;
    this.searchEndUserString = event.detail.searchEndUserString;
    this.searchResellerString = event.detail.searchResellerString;
  }
  
  ondatefilterchange(event) {
    this.fromDateFilter = event.detail.dateFrom;
    this.toDateFilter = event.detail.dateTo;
  }

  applyFilters() {
    let filterList = this.allData;
    console.log('FilteredData Length: ' + filterList.length);
    filterList = this.filterOrdersBasedOnEndUser(filterList, this.searchEndUserString);
    console.log('FilteredData Length: ' + filterList.length);
    filterList = this.filterOrdersBasedOnReseller(filterList, this.searchResellerString);
    console.log('FilteredData Length: ' + filterList.length);
    filterList = this.filterOrdersBasedOnSerialNumber(filterList, this.searchSerialNumberString);
    console.log('FilteredData Length: ' + filterList.length);
    filterList = this.filterOrdersBasedOnDateRange(filterList, this.fromDateFilter, this.toDateFilter);
    console.log('FilteredData Length: ' + filterList.length);
    
    this.filteredData = filterList;

    if(this.filteredData.length == 0) {
      this.showEmptyState = true;
    } else {
      //Sort the filtered data
      this.showEmptyState = false
      console.log('sort data');
      this.pageNumber = 1;
      this.sortData(this.sortedBy, this.sortDirection);
      this.setPaginationDetails();
    }
  }

  //Function to filter order array based on searched Order Id
  filterOrdersBasedOnSerialNumber(arr, searchSerialNumberString) {
    console.log('filter on serial Number: ' + searchSerialNumberString);
    return arr.filter(function(order) {
      if (order.serialNumbers != undefined && order.serialNumbers.toLowerCase().includes(searchSerialNumberString.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    });
  }

  //Function to filter order array based on searched EndUser
  filterOrdersBasedOnEndUser(arr, searchEndUserString) {
    console.log('filter on endUser');
    return arr.filter(function(order) {
      if (order.endUser != undefined && order.endUser.toLowerCase().includes(searchEndUserString.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    });
  }

  //Function to filter order array based on searched Reseller
  filterOrdersBasedOnReseller(arr, searchResellerString) {
    console.log('filter on resller');
    return arr.filter(function(order) {
      if (order.partner != undefined && order.partner.toLowerCase().includes(searchResellerString.toLowerCase())) {
        return true;
      } else {
        return false;
      }
    });
  }

  //Function to filter order array based on Date
  //assuming it is the orderDate
  filterOrdersBasedOnDateRange(arr, dateFrom, dateTo) {
    console.log('filter by date');
    return arr.filter(function(order) {
      if (dateFrom != null && dateTo != null) {
        return (
          order.orderDate >= dateFrom && order.orderDate <= dateTo
        );
      } else if (dateFrom && !dateTo) {
        return order.orderDate >= dateFrom;
      } else if (!dateFrom && dateTo) {
        return order.orderDate <= dateTo;
      } else {
        return false;
      }
    });
  }

  //Function to handle column sorting
  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    this.sortData(sortedBy, sortDirection);
  }

  //Function to sort data
  sortData(sortedBy, sortDirection) {
    const cloneData = [...this.filteredData];

    if (sortedBy === "orderDate" || sortedBy === "fulfillmentDate") {
      dateSort(cloneData, sortedBy, sortDirection);
    }
    this.filteredData = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  preparePaginationList() {
    let begin = (this.pageNumber - 1) * PAGE_LIMIT;
    let end = parseInt(begin) + parseInt(PAGE_LIMIT);
    this.ordersToDisplay = this.filteredData.slice(begin, end);
  }

  setPaginationDetails() {
    console.log('set pagination');
    this.preparePaginationList();
    this.paginationDetails.recordStart = (this.pageNumber - 1) * PAGE_LIMIT + 1;
    this.paginationDetails.recordEnd = this.paginationDetails.recordStart + this.ordersToDisplay.length - 1;
    this.paginationDetails.orderRecordCount = this.filteredData.length;
    this.paginationDetails.totalOrderRecords = this.filteredData.length;
    this.paginationDetails.totalPages = Math.ceil(this.paginationDetails.totalOrderRecords / PAGE_LIMIT);
    console.log('PageNumber: ' + this.pageNumber);
    if(this.pageNumber == 1) {
      this.paginationDetails.previousDisabled = true;
    } else {
      this.paginationDetails.previousDisabled = false;
    }

    if(this.pageNumber < this.paginationDetails.totalPages) {
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
    this.pageNumber = 1;
    this.setPaginationDetails();
  }

  handlePrevious() {
    this.pageNumber--;
    this.setPaginationDetails();
  }

  handleNext() {
    this.pageNumber++;
    this.setPaginationDetails();
  }

  handleLast() {
    this.pageNumber = this.paginationDetails.totalPages;
    this.setPaginationDetails();
  }

  handlePageChange(event) {
    this.pageNumber = parseInt(event.target.value);
    this.setPaginationDetails();
  }

  //Card Title
  get cardTitle(){
    if(this.isReadOnly) {
      return "";
    } else {
      return "Displaying (" + this.paginationDetails.recordStart + " - " + this.paginationDetails.recordEnd + ") of " + this.paginationDetails.totalOrderRecords + " Orders Found";
    }
  }

  showToastErrorEvent(){
    console.log('Error Toast');
    this.spinnerVisibility = false;
    const event = new ShowToastEvent({
      title: 'Error',
      message: this.errorMessage,
      variant: 'error'
    });
    this.dispatchEvent(event);
  }

  callRowAction(event){
    console.log('event...'+JSON.stringify(event.detail.row));
    const recId = event.detail.row.orderNumber;
    const actionName = event.detail.action.name;  
    if ( actionName === 'download' ) {
      getUrl({pageName: "PreviewSubscriptionCertificate"})
        .then(result => {
          console.log(result);
          this._pageURL = result + '?id=' + recId;
          console.log('this._pageURL...'+this._pageURL);
          window.open(this._pageURL, "_blank");
        })
        .catch(error => {
          this.error = error;
          console.log('Error fetching URL: ' + JSON.stringify(error) + this._pageURL);
        });
    }
  }

}