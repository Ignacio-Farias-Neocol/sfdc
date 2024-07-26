import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { stringSort, numberSort, dateSort } from "c/utilityModule";
import resetButtonFilter from '@salesforce/label/c.g_SerialSubFilter_ResetFilterButton_Label';
import searchHeader from '@salesforce/label/c.g_SerialSubFilter_Search_Header';
import serialExpDateHeader from '@salesforce/label/c.g_SerialSubFilter_SerialExpirationDate_Header';
import getQuoteDetails from "@salesforce/apex/QuoteListViewHelper.getQuotes";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_TYPE from '@salesforce/schema/User.Contact.Account.Type';
import Id from "@salesforce/user/Id";
import getUrl from "@salesforce/apex/ProductListViewHelper.getUrl";

import dateFrom from '@salesforce/label/c.g_SerialSubFilter_DateFrom_Label';
import dateTo from '@salesforce/label/c.g_SerialSubFilter_DateTo_Label';
import quoteNumber from '@salesforce/label/c.g_Quote_Number';
import serialNumbers from '@salesforce/label/c.g_Serial_Numbers';
import endUser from '@salesforce/label/c.g_My_Order_Page_End_User';
import contractEndDate from '@salesforce/label/c.g_Contract_End_Date';
import subsCount from '@salesforce/label/c.g_Subscription_Count';
import startDate from '@salesforce/label/c.g_Start_Date';
import endDate from '@salesforce/label/c.g_End_Date';
import extdFinalPrice from '@salesforce/label/c.g_Extended_Final_Price';
import quoteStatus from '@salesforce/label/c.g_Quote_Status';
import quoteType from '@salesforce/label/c.g_Quote_Type';
import linkToViewQuote from '@salesforce/label/c.g_Link_To_View_Quote';
//import pendingStatus from '@salesforce/label/c.g_Pending_Status';
import approvedStatus from '@salesforce/label/c.g_Approved_Status';
import notApprovedStatus from '@salesforce/label/c.g_Not_Approved_Status';
import draftStatus from '@salesforce/label/c.g_Draft_Status';
import inReviewStatus from '@salesforce/label/c.g_In_Review_Status';
import customerAcceptedStatus from '@salesforce/label/c.g_Customer_Accepted_Status';
import customerRejectedStatus from '@salesforce/label/c.g_Customer_Rejected_Status';
import deniedStatus from '@salesforce/label/c.g_Denied_Status';
import presentedStatus from '@salesforce/label/c.g_Presented_Status';
import searchSerialLabel from '@salesforce/label/c.g_SerialSubFilter_SearchSerial_Label';
import applyFilters from '@salesforce/label/c.g_Apply_Filters';

/**The default date range for date filters*/
const lookBackDayRange = 15;
const lookForwardDayRange = 30;
const lookBackMonthRange = 6;
const QUERY_LIMIT = 'Too many query rows: 50001';

const PAGE_LIMIT = 25;
const TABLECOLUMNS = [
    {
        type: "text",
        fieldName: "quoteNumber",
        label: quoteNumber,
        wrapText: true,
        sortable: true
      },
      {
        type: "text",
        fieldName: "endUser",
        label: endUser,
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
        type: "date-local",
        fieldName: "contractEndDate",
        label: contractEndDate,
        wrapText: true,
        sortable: true
      },
      {
        type: "number",
        fieldName: "subsCount",
        label: subsCount,
        wrapText: true,
        sortable: true,
        initialWidth: 75
      },
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
      {
        type: "number",
        fieldName: "extdFinalPrice",
        label: extdFinalPrice,
        wrapText: true,
        sortable: true,
        initialWidth: 75
      },
      {
        type: "text",
        fieldName: "quoteStatus",
        label: quoteStatus,
        wrapText: true,
        sortable: true
      },
      {
        type: "text",
        fieldName: "quoteType",
        label: quoteType,
        wrapText: true,
        sortable: true
      },
      {
        type: "button",
        fieldName: "quoteLink",
        label: linkToViewQuote,
        typeAttributes: {
            label: {
                fieldName: 'url'
            },
            disabled: {
              fieldName: 'disableViewQuote'
            },
            variant: 'base',
            name: 'view'
        }
      }
  ];

const DISTITABLECOLUMNS = [
  {
      type: "text",
      fieldName: "quoteNumber",
      label: quoteNumber,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "endUser",
      label: endUser,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "reseller",
      label: "Reseller",
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
      type: "date-local",
      fieldName: "contractEndDate",
      label: contractEndDate,
      wrapText: true,
      sortable: true
    },
    {
      type: "number",
      fieldName: "subsCount",
      label: subsCount,
      wrapText: true,
      sortable: true,
      initialWidth: 75
    },
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
    {
      type: "number",
      fieldName: "extdFinalPrice",
      label: extdFinalPrice,
      wrapText: true,
      sortable: true,
      initialWidth: 75
    },
    {
      type: "text",
      fieldName: "quoteStatus",
      label: quoteStatus,
      wrapText: true,
      sortable: true
    },
    {
      type: "text",
      fieldName: "quoteType",
      label: quoteType,
      wrapText: true,
      sortable: true
    },
    {
      type: "button",
      fieldName: "quoteLink",
      label: linkToViewQuote,
      typeAttributes: {
          label: {
              fieldName: 'url'
          },
          disabled: {
            fieldName: 'disableViewQuote'
          },
          variant: 'base',
          name: 'view'
      }
    }
];

export default class QuoteListView extends NavigationMixin(LightningElement) {

    label = {
        resetButtonFilter,
        searchHeader,
        serialExpDateHeader,
        dateFrom,
        dateTo,
        quoteNumber,
        serialNumbers,
        contractEndDate,
        subsCount,
        startDate,
        endDate,
        extdFinalPrice,
        quoteStatus,
        quoteType,
        linkToViewQuote,
        //pendingStatus,
        approvedStatus,
        notApprovedStatus,
        draftStatus,
        inReviewStatus,
        customerAcceptedStatus,
        customerRejectedStatus,
        deniedStatus,
        presentedStatus,
        searchSerialLabel,
        noQuoteToDisplay: 'No Quotes to Display',
        applyFilters
    };

    settingsLoaded = false;

    quoteListData = [];
    allQuoteListData = [];
    quotesToDisplay = [];
    @track columns = TABLECOLUMNS;

    @track statusesFilter = [];
    @api statuses = [/*pendingStatus,*/approvedStatus];
    @api recordId;
    userId = Id;
    entityId;
    _accountType;

    searchSerialString = '';
    searchEndUserString = '';
    searchResellerString = '';

    dateFrom = '';
    dateTo = '';
    fromDateDefault = '';
    toDateDefault = '';
    minFromDate = '';
    maxToDate = '';

    showQuoteNoSearch = false;
    showEndUserSearch = false;
    showResellerSearch = false;

    quoteNoSearchLabel = 'Serial Number';
    endUserSearchLabel = 'End User';
    resellerSearchLabel = 'Reseller';

    defaultSortDirection = "asc";
    sortDirection = "asc";
    sortedBy;

    showEmptyState = true;
    spinnerVisibility = false;
    errorMessage = '';

    filters = {
        dateFrom: this.dateFrom,
        dateTo: this.dateTo
    };

    paginationDetails = {
      totalQuoteRecords: 0,
      quoteRecordCount: 0,
      recordStart: 0,
      recordEnd: 0,
      previousDisabled: false,
      nextDisabled: false
    };
  
    pageOptions=[];
  
    pageNumber = 1;

    @wire(getRecord, { recordId: '$userId', fields: [ACCOUNT_TYPE] })
    wiredUser({ error, data }) {
      console.log('gettin user data');
      if(data) {
        if(getFieldValue(data, ACCOUNT_TYPE).includes('Distributor')) {
          this.showResellerSearch = true;
          this.columns = DISTITABLECOLUMNS;
        }
        this.settingsLoaded = true;
      }
    }

    @api
    get accountType() {
    return this._accountType;
    }

    set accountType(value) {
      this._accountType = value;
      this.entityId = value === "Internal" ? this.recordId : this.userId; 

      if(value){
        this._accountType = value;
        if(value == 'Customer') {
          this.showQuoteNoSearch = true;
        } else if (value == 'Reseller') {
          this.showQuoteNoSearch = true;
          this.showEndUserSearch = true;
        } 
      }
    }

    formatDateVals(date) {
      return date.toISOString().split('T')[0];
    }

    connectedCallback() {
      console.log('Connected callback inital load');

      var today = new Date();

      this.fromDateDefault = this.formatDateVals(new Date(new Date().setDate(today.getDate() - lookBackDayRange)));
      this.toDateDefault = this.formatDateVals(new Date(new Date().setDate(today.getDate() + lookForwardDayRange)));
      this.minFromDate = this.formatDateVals(new Date(new Date().setMonth(today.getMonth() - lookBackMonthRange)));
      this.maxToDate = '';

      this.filters.dateFrom = this.fromDateDefault;
      this.filters.dateTo = this.toDateDefault;

      this.getQuotes();

    }

    resetFilters(){
        this.template.querySelector('c-status-search-filter').reset();
        this.template.querySelector('c-text-search-filter').reset();
        this.template.querySelector('c-date-search-filter').reset();
        this.filters.dateFrom = this.fromDateDefault;
        this.filters.dateTo = this.toDateDefault;
        this.getQuotes();
    }

    getQuotes() {
      console.log('Getting Quotes');
      this.spinnerVisibility = true;
      getQuoteDetails({entityId: this.entityId, 
                        accountType: this._accountType,
                        fromDate: this.filters.dateFrom,
                        toDate: this.filters.dateTo})
        .then(result => {
          console.log('Retrieved Quote Details.');
          this.parseQuoteDetails(result);
        })
        .catch(error => {
          console.log('error...' + JSON.stringify(error));
          this.spinnerVisibility = false;
          let message = error.body.message;
          if(message != QUERY_LIMIT) {
            this.errorMessage = 'Something went wrong';
          } else {
            this.errorMessage = 'Too many Quotes found. Please refine your search and try again.';
          }
          this.showToastErrorEvent();
        })
    }


    parseQuoteDetails(data) {
        let _tempQuoteListData = [];
        if (data) {
            let quote = data;
            for (let i = 0; i < quote.length; i++) {
                var quoteRow = {};
                let viewQuote = true;
                quoteRow.quoteNumber = quote[i].Name;
                /*if(quote[i].SBQQ__Status__c === draftStatus || quote[i].SBQQ__Status__c === inReviewStatus){
                    quoteRow.quoteStatus = pendingStatus;
                }else*/ if(quote[i].SBQQ__Status__c === approvedStatus || quote[i].SBQQ__Status__c === presentedStatus || quote[i].SBQQ__Status__c === customerAcceptedStatus){
                    quoteRow.quoteStatus = approvedStatus;
                }else if(quote[i].SBQQ__Status__c === deniedStatus || quote[i].SBQQ__Status__c === customerRejectedStatus){
                    quoteRow.quoteStatus = notApprovedStatus;
                }
                quoteRow.quoteType = quote[i].SBQQ__Type__c;
                quoteRow.contractEndDate = quote[i].Original_Contract_End_Date__c;
                if(quoteRow.quoteStatus === approvedStatus){
                  quoteRow.quoteLink = '/quote/' +quote[i].Id;
                  viewQuote = false;
                }
                quoteRow.disableViewQuote = viewQuote;
                let qli = quote[i].SBQQ__LineItems__r;
                let priceSum = 0;
                let startDate, endDate;
                let serNumbers = '';
                if(qli) {
                  for(let j = 0; j < qli.length; j++){
                    priceSum += qli[j].Extended_Final_Price__c;
                    startDate = startDate < qli[j].SBQQ__StartDate__c ? startDate : qli[j].SBQQ__StartDate__c;
                    endDate = endDate < qli[j].SBQQ__EndDate__c ? endDate : qli[j].SBQQ__EndDate__c;
                    // Aditya - Comma separated issue change - Start
                    if(qli[j].SBCF_Serial_Number__c != '' && qli[j].SBCF_Serial_Number__c != null){
                      if(serNumbers != ''){
                        if(!serNumbers.includes(qli[j].SBCF_Serial_Number__c)){
                          serNumbers = serNumbers +', '+qli[j].SBCF_Serial_Number__c;
                        }
                      }
                      else{
                        serNumbers = qli[j].SBCF_Serial_Number__c;
                      }
                      console.log('serNumbers after concat...'+serNumbers);
                    }
                    // Aditya - Comma separated issue change - End
                  }
                  quoteRow.extdFinalPrice = priceSum;
                  quoteRow.startDate = startDate;
                  quoteRow.endDate = endDate;
                  quoteRow.subsCount = qli.length;
                  quoteRow.serialNumbers = serNumbers; // // Aditya - Comma separated issue change
                }
                quoteRow.endUser = quote[i].SBQQ__Account__r.Name;
                quoteRow.url = "View";
                quoteRow.id = quote[i].Id;
                quoteRow.reseller = quote[i].SBQQ__Opportunity2__r?.SBQQ__RenewedContract__r?.Reseller__r?.Name;
                _tempQuoteListData.push(quoteRow);
            }
            this.quoteListData = _tempQuoteListData;
            this.allQuoteListData = _tempQuoteListData;
            this.statusesFilter = [/*pendingStatus,*/approvedStatus];
            this.applyFilters();
            this.spinnerVisibility = false;
            console.log('this.quoteListData...'+JSON.stringify(this.quoteListData));
        }
        else if (error){
            console.log('Error...'+JSON.stringify(error));
            this.errorMessage = 'There was an error loading quotes';
            this.spinnerVisibility = false;
        }
    }

    statusfilterchange(event){
        this.statusesFilter = event.detail.statusFilter;
    }

    datefilterchange(event){
      this.filters.dateFrom = event.detail.dateFrom;
      this.filters.dateTo = event.detail.dateTo;
    }

    textfilterchange(event){
      this.searchSerialString = event.detail.searchTextString;
      this.searchEndUserString = event.detail.searchEndUserString;
      this.searchResellerString = event.detail.searchResellerString;
    }

    applyFilters(){
        console.log('this.allQuoteListData...'+this.allQuoteListData);
        this.quoteListData = this.allQuoteListData;
        if (this.statusesFilter != null) {
            this.quoteListData = this.filterQuotesBasedOnValueList(
                this.quoteListData,
              "quoteStatus",
              this.statusesFilter
            );
        }
        if (!((this.filters.dateFrom == null || this.filters.dateFrom == '') && (this.filters.dateTo == null || this.filters.dateTo == ''))) {
          this.quoteListData = this.filterQuotesBasedOnDateRange(
              this.quoteListData,
              this.filters.dateFrom,
              this.filters.dateTo
          );
        }
        if(!(this.searchSerialString == null || this.searchSerialString == '')){
          this.quoteListData = this.filterQuotesBasedOnSerialNumber(
              this.quoteListData,
              this.searchSerialString
          );
        }

        if(!(this.searchEndUserString == null || this.searchEndUserString == '')){
          this.quoteListData = this.filterQuotesBasedOnEndUser(
              this.quoteListData,
              this.searchEndUserString
          );
        }

        if(!(this.searchResellerString == null || this.searchResellerString == '')){
          this.quoteListData = this.filterQuotesBasedOnReseller(
              this.quoteListData,
              this.searchResellerString
          );
        }

        if(this.quoteListData.length == 0) {
          this.showEmptyState = true;
        } else {
          this.showEmptyState = false;
          this.sortData(this.sortedBy, this.sortDirection);
          this.pageNumber = 1;
          this.setPaginationDetails();
        }

      console.log('after filter this.quoteListData...'+JSON.stringify(this.quoteListData));
    }

    filterQuotesBasedOnValueList(arr, fieldName, filterValues) {
        console.log('filterQuotesBasedOnValueList...'+arr+' '+fieldName+' '+filterValues);
        return arr.filter(function(quote) {
          return filterValues.some(function(value) {
            if (quote[fieldName] === value) {
              return true;
            } else {
              return false;
            }
          });
        });
    }

    //Function to filter serial array based on Date
    filterQuotesBasedOnDateRange(arr, dateFrom, dateTo) {
        return arr.filter(function(quote) {
            if (dateFrom && dateTo) {
                return (
                quote.contractEndDate >= dateFrom && quote.contractEndDate <= dateTo
                );
            } else if (dateFrom && !dateTo) {
                return quote.contractEndDate >= dateFrom;
            } else if (!dateFrom && dateTo) {
                return quote.contractEndDate <= dateTo;
            } else {
                return false;
            }
        });
    }

    filterQuotesBasedOnSerialNumber(arr, searchSerialNumber) {
        return arr.filter(function(quote) {
          if (quote.serialNumbers && quote.serialNumbers.toLowerCase().includes(searchSerialNumber.toLowerCase())) {
            return true;
          } else {
            return false;
          }
        });
    }
    
    filterQuotesBasedOnEndUser(arr, endUser) {
      return arr.filter(function(quote) {
        if (quote.endUser && quote.endUser.toLowerCase().includes(endUser.toLowerCase())) {
          return true;
        } else {
          return false;
        }
      });
    }

    //Function to filter order array based on searched Reseller
    filterQuotesBasedOnReseller(arr, searchResellerString) {
      return arr.filter(function(quote) {
        if (quote.reseller != undefined && quote.reseller.toLowerCase().includes(searchResellerString.toLowerCase())) {
          return true;
        } else {
          return false;
        }
      });
    }

    onHandleSort(event) {
      const { fieldName: sortedBy, sortDirection } = event.detail;
      this.sortData(sortedBy, sortDirection);
    }
  
    //Function to sort data
    sortData(sortedBy, sortDirection) {
      const cloneData = [...this.quoteListData];
  
      if (sortedBy === "contractEndDate") {
        dateSort(cloneData, sortedBy, sortDirection);
      }
      this.quoteListData = cloneData;
      this.sortDirection = sortDirection;
      this.sortedBy = sortedBy;
    }

    callRowAction(event){
      console.log('event...'+JSON.stringify(event.detail.row));
      const recId =  event.detail.row.id;
      const actionName = event.detail.action.name;  
      if ( actionName === 'view' ) {
        getUrl({pageName: "QuoteDetail"})
          .then(result => {
            console.log(result);
            //SFDC-14547: Removing ProductName and Account Id because these fields are on Serial now and can be fetched from the record.
            this._pageURL = result + 
                            '?id=' + recId;
            window.open(this._pageURL, "_blank");
          })
          .catch(error => {
            this.error = error;
            console.log('Error fetching URL: ' + JSON.stringify(error) + this._pageURL);
          });
      }
    }

    preparePaginationList() {
      let begin = (this.pageNumber - 1) * PAGE_LIMIT;
      let end = parseInt(begin) + parseInt(PAGE_LIMIT);
      this.quotesToDisplay = this.quoteListData.slice(begin, end);
    }
  
    setPaginationDetails() {
      console.log('set pagination');
      this.preparePaginationList();
      this.paginationDetails.recordStart = (this.pageNumber - 1) * PAGE_LIMIT + 1;
      this.paginationDetails.recordEnd = this.paginationDetails.recordStart + this.quotesToDisplay.length - 1;
      this.paginationDetails.quoteRecordCount = this.quoteListData.length;
      this.paginationDetails.totalQuoteRecords = this.quoteListData.length;
      this.paginationDetails.totalPages = Math.ceil(this.paginationDetails.totalQuoteRecords / PAGE_LIMIT);
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
        return "Displaying (" + this.paginationDetails.recordStart + " - " + this.paginationDetails.recordEnd + ") of " + this.paginationDetails.totalQuoteRecords + " Quotes Found";
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
}