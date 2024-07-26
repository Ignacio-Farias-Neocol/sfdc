import { LightningElement, api } from 'lwc';

//Import custom labels
import dateFrom from '@salesforce/label/c.g_SerialSubFilter_DateFrom_Label';
import dateTo from '@salesforce/label/c.g_SerialSubFilter_DateTo_Label';

export default class DateSearchFilter extends LightningElement {

  @api 
  get fromDateDefault() {
    return this._dateFromDefault;
  }

  set fromDateDefault(value) {
    if(value) {
      this._dateFromDefault = value;
      this.dateFrom = this._dateFromDefault;
      this.filters.dateFrom = this.dateFrom;
      console.log('DateFrom: ' + this.dateFrom);
    }
  }
  
  @api 
  get toDateDefault() {
    return this._dateToDefault;
  }

  set toDateDefault(value) {
    if(value) {
      this._dateToDefault = value;
      this.dateTo = this._dateToDefault;
      this.filters.dateTo = this.dateTo;
      console.log('DateTo: ' + this.dateTo);
    }
  }
  @api 
  get minFromDate() {
    return this._minFromDate;
  };

  set minFromDate(value) {
    if(value) {
      this._minFromDate = value;
    }
  }

  @api
  get maxToDate() {
    return this._maxToDate;
  };

  set maxToDate(value) {
    if(value) {
      this._maxToDate = value;
    }
  }

  @api dateSearchLabel = '';

  // @api reset() {
  //   console.log('reset date filters.....');
  //   this.dateFrom = '';
  //   this.dateTo = '';
  //   this.filters.dateFrom = '';
  //   this.filters.dateTo = '';
  // };

  connectedCallback() {
    this.reset();
  }

  filters = {
    dateFrom: this.dateFrom,
    dateTo: this.dateTo
  }

  labels = {
    dateFrom,
    dateTo
  }

  //Local Date values
  //Static defaults for reset
  _dateFromDefault = '';
  _dateToDefault = '';
  _minFromDate = '';
  _maxToDate = '';
  //Dynamic selected
  dateFrom = '';
  dateTo = '';

  @api reset() {
    console.log('not api reset date filters.....');
    this.dateFrom = this.fromDateDefault;
    this.dateTo = this.toDateDefault;
    this.filters.dateFrom = this._dateFromDefault;
    this.filters.dateTo = this._dateToDefault;
  }

  //Event handler for the onchange event of reseller search field
  handleDateChange(event) {
    //Update filters object
    if (event.target.name === "dateFrom") {
      //Update filters object
      this.dateFrom = event.target.value;
      this.filters.dateFrom = event.target.value;
    } else if (event.target.name === "dateTo") {
      //Update filters object
      this.dateTo = event.target.value;
      this.filters.dateTo = event.target.value;
    }
    //Fire the event
    this.publishEvent();
  }

  //Function to create and publish datefilterchange event to parent component
  publishEvent() {
    console.log('datefilterchange event');
    //Create an event
    const filterEvent = new CustomEvent("datefilterchange", {
      detail: this.filters
    });

    //Raise an event
    this.dispatchEvent(filterEvent);
  }
}