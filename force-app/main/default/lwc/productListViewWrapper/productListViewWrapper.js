import { LightningElement, wire, track, api } from "lwc";
import Id from "@salesforce/user/Id";

/** getSerialDetails() method in ProductListViewHelper Apex class */
import getSerialSubDetails from "@salesforce/apex/ProductListViewHelper.getSerialSubDetails";

export default class ProductListViewWrapper extends LightningElement {

  //Determines loading spinner visibility
  spinnerVisibility = true;

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

  //Record ID
  @api recordId;

  //Determines if we are in internal or external version
  external = true;

  //Serials to be sent to child component
  serials;

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

  /**
   * Load the list of available serials. 0054D000001XS0PQAW
   */
  @wire(getSerialSubDetails, {
    entityId: "$entityId",
    accountType: "$_accountType"
  })
  wiredSerials({ error, data }) {
    if (data) {
      this.serialSubs = data;
      if (data.serials && data.serials.length > 0) {
        this.serials = data.serials;
        // console.log("SERIALS: " + JSON.stringify(this.serials));
        this.showEmptyState = false;
      }

      //Hide spinner
      this.spinnerVisibility = false;

      //Reset error value
      this.error = undefined;
    } else if (error) {
      this.showEmptyState = true;
      this.spinnerVisibility = false;
      this.error = error;
      this.serials = undefined;
      this.serialSubs = undefined;
    }

    if(!this.spinnerVisibility && (!this.serials || this.serials.length === 0)){
      this.showEmptyState = true;
    }
    console.log("EMPTYSTATE: " + this.showEmptyState);
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
    //Get all serials to start the filtering process
    this.serials = this.serialSubs.serials;
    
    if (this.serialSubs && this.serialSubs.serials) {
      // console.log("Filters: " + JSON.stringify(event.detail));

      if(event.detail.searchKey){
        //SearchKey words
        const searchKeyWords = event.detail.searchKey.trim().split(" ");
        // console.log("Search Key From Event: " + JSON.stringify(searchKeyWords));

        //Get serials based on the searchKey criteria
        var serialSearchResult = this.filterSerialsBasedOnString(
          this.serialSubs.serials,
          searchKeyWords
        );

        //Find values that are in serialSubs.serials but not in serialSearchResult.
        //This is used to run a second level of string search on Subscriptions
        var filteredOutSerials = this.serialSubs.serials.filter(function(
          serial1
        ) {
          return !serialSearchResult.some(function(serial2) {
            return serial1.id == serial2.id;
          });
        }); 
        
        //Run the searchKey search on Subscriptions
        var subSearchResult = [];
        if (this.serialSubs.serialSubMap) {
          for (let i = 0; i < filteredOutSerials.length; i++) {
            const subs = this.serialSubs.serialSubMap[filteredOutSerials[i].id];
            for (let j = 0; j < subs.length; j++) {
              if (
                searchKeyWords.some(function(word) {
                  if(subs[j].productName){
                    return subs[j].productName
                    .toLowerCase()
                    .includes(word.toLowerCase());
                  }
                  else{
                    return false;
                  }

                })
              ) {
                subSearchResult.push(filteredOutSerials[i]);
                break;
              }
            }
          }
        }  
        //Add the serials obtained by filtering the Subscription and assign it to the serials variable being sent out
        this.serials = serialSearchResult.concat(subSearchResult); 

        // console.log("Filtered result: " + JSON.stringify(serialSearchResult));
        // console.log("Filtered Out result: " + JSON.stringify(filteredOutSerials));
      }

      //Perform Date filter
      if (event.detail.dateFrom || event.detail.dateTo) {
        this.serials = this.filterSerialsBasedOnDateRange(
          this.serials,
          event.detail.dateFrom,
          event.detail.dateTo
        );
      }

      //Perform Status filter
      if (event.detail.statusFilter != null) {
        this.serials = this.filterSerialsBasedOnValueList(
          this.serials,
          "statusNumber",
          event.detail.statusFilter
        );
      }

      //Perform Business Group filter
      if(event.detail.businessGroupFilter != null){
        this.serials = this.filterSerialsBasedOnValueList(
          this.serials,
          "businessGroup",
          event.detail.businessGroupFilter
        );
      }
    }
    console.log("Filtering ended");
  }

  //Function to filter serial array based on search key
  filterSerialsBasedOnString(arr, searchWords) {
    return arr.filter(function(serial) {
      return searchWords.some(function(word) {
        if (serial.productName && serial.productName.toLowerCase().includes(word.toLowerCase())) {
          return true;
        } else if (serial.serialNumber && serial.serialNumber.toLowerCase().includes(word.toLowerCase())) {
          return true;
        } else {
          return false;
        }
      });
    });
  }

  //Function to filter serial array based on Date
  filterSerialsBasedOnDateRange(arr, dateFrom, dateTo) {
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
    return arr.filter(function(serial) {
      return filterValues.some(function(value) {
        if (serial[fieldName] === value) {
          return true;
        } else {
          return false;
        }
      });
    });
  }
}