import { LightningElement, api } from 'lwc';

//Import Custom Labels
import searchHeader from '@salesforce/label/c.g_SerialSubFilter_Search_Header';
import endUserFilterLabel from '@salesforce/label/c.g_My_Order_Page_End_User';
import resellerFilterLabel from '@salesforce/label/c.g_My_Orders_Page_Reseller_Filter';
const DELAY = 350;

export default class TextSearchFilter extends LightningElement {

  //Flags to determine if the search field should be rendered
  @api showTextSearch = false;
  @api showEndUserSearch = false;
  @api showResellerSearch = false;

  @api searchTextLabel = '';

  //Resets the search fields to original value
  @api reset() {
    console.log('reset text filters.....');
    this.searchTextString = '';
    this.searchEndUserString = '';
    this.searchResellerString = '';

    this.filters = {
      searchTextString: '',
      searchEndUserString: '',
      searchResellerString: ''
    };

    this.createAndPublishEvent();
  }

  searchTextString;
  searchEndUserString;
  searchResellerString;

  filters = {
    searchTextString: '',
    searchEndUserString: '',
    searchResellerString: ''
  };

  labels = {
    searchHeader,
    endUserFilterLabel,
    resellerFilterLabel
  };

  //Event handler for the onchange event of generic text search field
  handleTextKeyChange(event) {
    console.log('handleSerialKeyChange....'+ event.target.value);
    //Update filters object
    this.searchTextString = event.target.value;
    this.filters.searchTextString = event.target.value;

    //Fire the event
    this.createAndPublishEvent();
  }

  //Event handler for the onchange event of end user search field
  handleEndUserKeyChange(event) {
    //Update filters object
    this.searchEndUserString = event.target.value;
    this.filters.searchEndUserString = event.target.value;

    //Fire the event
    this.createAndPublishEvent();
  }

  //Event handler for the onchange event of reseller search field
  handleResellerKeyChange(event) {
    //Update filters object
    this.searchResellerString = event.target.value;
    this.filters.searchResellerString = event.target.value;

    //Fire the event
    this.createAndPublishEvent();
  }

    // //Fire the event after a delay for any filter changes
    // delayedFireFilterChangeEvent() {
    //   // Debouncing this method: Do not actually fire the event as long as this function is
    //   // being called within a delay of DELAY. This is to avoid a very large number of Apex
    //   // method calls in components listening to this event.
    //   window.clearTimeout(this.delayTimeout);
    //   // eslint-disable-next-line @lwc/lwc/no-async-operation
    //   this.delayTimeout = setTimeout(() => {
    //     this, this.createAndPublishEvent();
    //   }, DELAY);
    // }

  //Function to create and publish textsearchchange event to parent component
  createAndPublishEvent() {
    console.log('textsearchchange event');
    //Create an event
    const filterEvent = new CustomEvent("textsearchchange", {
      detail: this.filters
    });

    //Raise an event
    this.dispatchEvent(filterEvent);
  }
}