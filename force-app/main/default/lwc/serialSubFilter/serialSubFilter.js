import { LightningElement, api } from "lwc";

/** The delay used when debouncing event handlers before firing the event. */
const DELAY = 350;

export default class SerialSubFilter extends LightningElement {
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
      console.log("Account type in filter: " + value);
    } else {
      this.layoutItemSize = 4;
      this.showBusinessGroup = false;
      this.filters.businessGroupFilter = null;
    }
  }

  //Layout Item Size
  layoutItemSize = 4;

  //Flag to determine the visibility of business group filter
  showBusinessGroup;

  searchKey = "";
  dateFrom;
  dateTo;

  filters = {
    searchKey: this.searchKey,
    statusFilter: [1, 2, 3]
  };

  //Local Variable for account type
  _accountType;

  //Event handler for the onchange event of search field
  handleSearchKeyChange(event) {
    this.searchKey = event.target.value;

    //Update filters object
    this.filters.searchKey = this.searchKey;

    //Fire the event
    this.delayedFireFilterChangeEvent();
  }

  //Event handler for the onchange event of date fields
  handleDateChange(event) {
    if (event.target.name === "dateFrom") {
      //Update filters object
      this.filters.dateFrom = event.target.value;
    } else if (event.target.name === "dateTo") {
      //Update filters object
      this.filters.dateTo = event.target.value;
    }

    //Fire the event
    this.delayedFireFilterChangeEvent();
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

    //Fire the event. We don't need a delay for checkboxes
    this.createAndPublishEvent();
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

    //Fire the event. We don't need a delay for checkboxes
    this.createAndPublishEvent();
  }

  //Function to handle reset filters button
  resetFilters() {
    // //Set Searchkey to blank
    this.searchKey = "";
    this.filters.searchKey = this.searchKey;

    //Set dates to blank
    this.template.querySelectorAll(".expDate").forEach((dateInput) => {
      dateInput.value = "";
      if (dateInput.name === "dateFrom") {
        this.filters.dateFrom = "";
      } else if (dateInput.name === "dateTo") {
        this.filters.dateTo = "";
      }
    });

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

    //Fire the event
    this.createAndPublishEvent();
  }

  //Fire the event after a delay for searchkey and date changes
  delayedFireFilterChangeEvent() {
    // Debouncing this method: Do not actually fire the event as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex
    // method calls in components listening to this event.
    window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
      this, this.createAndPublishEvent();
    }, DELAY);
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