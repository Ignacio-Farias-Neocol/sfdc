import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import TYPE_FIELD from '@salesforce/schema/Account.Type';
import ADDRESS_FIELD from '@salesforce/schema/Account.BillingAddress';
import STREET_FIELD from '@salesforce/schema/Account.BillingStreet';
import COUNTRY_FIELD from '@salesforce/schema/Account.BillingCountry';
import COUNTRY_CODE_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_CODE_FIELD from '@salesforce/schema/Account.BillingStateCode';
import CITY_FIELD from '@salesforce/schema/Account.BillingCity';
import STATE_FIELD from '@salesforce/schema/Account.BillingState';
import POSTALCODE_FIELD from '@salesforce/schema/Account.BillingPostalCode';
import WEBSITE_FIELD from '@salesforce/schema/Account.Website';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import DUNS_FIELD from '@salesforce/schema/Account.D_B_DUNS_Number__c';
import CURRENCY_FIELD from '@salesforce/schema/Account.CurrencyIsoCode';
import findAccountSBCByName from '@salesforce/apex/searchBeforeCreateController.findAccountSBCByName';
import getMatchResults from '@salesforce/apex/searchBeforeCreateController.getMatchResults';
import CreateAccount from '@salesforce/apex/searchBeforeCreateController.CreateAccount';
// import getCountryList from '@salesforce/apex/searchBeforeCreateController.getCountryList';
import activateSessionPermSet from '@salesforce/apex/searchBeforeCreateController.activateSessionPermSet';


//Account Actions
const accountActions = [
  { label: 'Clone - Business Group', fields: ['Type'] },
  { label: 'Clone - Status', fields: ['Status'] },
  { label: 'Clone', fields: [] }
];

// Account Columns
const ACC_COLUMNS = [
  {
    label: 'Name', fieldName: 'Name', initialWidth: 160, sortable: true, typeAttributes: {
      label: { fieldName: 'Name' },
      tooltip: { fieldName: 'Name' },
      target: '_blank'
    }
  },
  { label: 'Type', fieldName: 'Type', initialWidth: 100, sortable: true },
  { label: 'Country', fieldName: 'BillingCountry', initialWidth: 100, sortable: true },
  { label: 'State/Province', fieldName: 'BillingState', initialWidth: 100, sortable: true },
  { label: 'City', fieldName: 'BillingCity', initialWidth: 100, sortable: true },
  { label: 'Website', fieldName: 'Website', type: 'url', initialWidth: 160, sortable: true },
  { label: 'Phone', fieldName: 'Phone', initialWidth: 100, sortable: true },
  { label: 'DUNS Number', fieldName: 'D_B_DUNS_Number__c', initialWidth: 100, sortable: true },
  { label: 'ARR', fieldName: 'ARR__c', type: 'currency', initialWidth: 80, sortable: true },
  { label: 'Currency', fieldName: 'CurrencyIsoCode', initialWidth: 80, sortable: true },

  {
    type: 'action',
    typeAttributes: {
      rowActions: accountActions
    }
  }
];

// Account Enrich Columns
const ACC_ENRICH_COLUMNS = [
  { label: 'Name', fieldName: 'Name', initialWidth: 160, sortable: true },
  { label: 'Website', fieldName: 'Website', type: 'url', initialWidth: 160, sortable: true },
  { label: 'Corporate Linkage', fieldName: 'Description', initialWidth: 160, sortable: true },
  { label: 'DUNS', fieldName: 'D_B_DUNS_Number__c', initialWidth: 100, sortable: true },
  { label: 'Country', fieldName: 'BillingCountry', initialWidth: 100, sortable: true },
  { label: 'State/Province', fieldName: 'BillingState', initialWidth: 100, sortable: true },
  { label: 'City', fieldName: 'BillingCity', initialWidth: 100, sortable: true },
  { label: 'Confidence Code', fieldName: 'DNBConnect__D_B_Match_Confidence_Code__c', initialWidth: 80, sortable: true }
];

export default class SearchBeforeCreate_AccountCreate extends NavigationMixin(LightningElement) {


  @api recordTypeId;
  @api objectApiName ;

  _countries = [];
  _countryToStates = {};
  selectedCountry;
  selectedState;

  objectApiName = ACCOUNT_OBJECT;
  nameField = NAME_FIELD;
  typefield = TYPE_FIELD;
  phoneField = PHONE_FIELD;
  websiteField = WEBSITE_FIELD;
  dunsField = DUNS_FIELD;
  addressField = ADDRESS_FIELD;
  countryField = COUNTRY_FIELD;
  countryCodeField = COUNTRY_CODE_FIELD;
  streetField = STREET_FIELD;
  cityField = CITY_FIELD;
  stateField = STATE_FIELD;
  stateCodeField = BILLING_STATE_CODE_FIELD;
  postalcodeField = POSTALCODE_FIELD;
  currencyfield = CURRENCY_FIELD;
  @wire(CurrentPageReference) pageRef;
  currentPageReference;

  accNameDisabled=false;
  accTypeDisabled=false;
  accPhoneDisabled=true;
  accDunsDisabled=false;
  accWebsiteDisabled = false;
  accStreetDisabled = true;
  accCountryDisabled = false;
  accCityDisabled=true;
  accStateDisabled=true;
  accZipDisabled=true;
  accCurrencyDisabled=true;
  accSeachBtnDisabled=false;

  // Page Section
  titleString = 'Create new Account';
  superTitleString = 'Account';
  showSpinner = false;
  // Page Section

  // Accounts Section
  ACCOUNT_COLUMNS = ACC_COLUMNS;
  DEFAULT_PAGE = 'ACCOUNT_RESULTS_PAGE';
  ACCOUNT_RESULTS_PAGE = 'accountResults';
  ACCOUNT_CREATE_PAGE = 'accountCreate';
  ACCOUNT_PAGE_HEADER = 'Select an Existing Account';
  ACCOUNT_CREATION_HEADER = 'Account Information';
  ACCOUNT_FORM_ID = 'new-account';
  ///Account Clone Section
  ACCOUNT_CLONE_PAGE = 'accountClone';
  ACCOUNT_CLONE_PAGE_HEADER = 'Account Information';
  ACCOUNT_CLONE_ID = 'clone-account';
  isAccounttableEmpty = false;
  @track accountCloneFields = []; // Fields to be shown on the clone form
  CLONE_FIELD_MAPPINGS = {
    'Type': 'Type',
    'Status__c': 'Status',
    'CurrencyIsoCode': 'Currency'
  };
  @track accountCloneFieldOptions = Object.keys(this.CLONE_FIELD_MAPPINGS); // Options for fields
  originalAccount = [];
  get fieldOptionsWithLabels() {
    console.log('this.accountCloneFieldOptions:: ' + JSON.stringify(this.accountCloneFieldOptions));
    return this.accountCloneFieldOptions.map(field => {
      return {
        apiName: field,
        label: this.CLONE_FIELD_MAPPINGS[field]
      };
    });

  }
    // Use a getter to extract the recordTypeId from the page state
  get recordTypeId() {
      return this.pageRef && this.pageRef.state.recordTypeId ? this.pageRef.state.recordTypeId : null;
  }
  //Account Clone Section

  //  Accounts Enrichment Section
  ENRICH_COLUMNS = ACC_ENRICH_COLUMNS;
  ACCOUNT_ENRICH_HEADER = 'Select an Account from D&B';
  ACCOUNT_ENRICH_PAGE = 'accountEnrich';
  @track accountEnrichResults = [];
  isAccountEnrichtableEmpty = false;


  @track accountResults = [];
  selectedAccount;
  @track sortDirection = 'desc';
  @track sortedBy;
  pageHistoryArray = [];

  acctbtndisabled = true;

  @track selectedAccountIdRow = [];

  @api
  currentPage = this.ACCOUNT_RESULTS_PAGE;

  originalAcc;
  accString;
  accObject;
  navRecId;
  createDisabled = true;
  @track disabledFields = {};
  accountname;
  Type = "";
  address;
  street;
  city;
  country;
  state;
  zip;
  website;
  phone;
  dunsnum;
  currency;
  busgroup = "";
  parentid;
  employeecount;
  industry;
  countrycode;
  creationSourceAudit = 'Manual';
  isEnriched = false;
  isAccountEnriched = false;
  isAccountCreated = false;
  isError = false;
  isAccountSaved = false;

  @wire(getPicklistValues, {
    recordTypeId: '012000000000000AAA',
    fieldApiName: COUNTRY_CODE_FIELD
  })
  wiredCountires({ data }) {
      this._countries = data?.values;
  }

  @wire(getPicklistValues, {
    recordTypeId: '012000000000000AAA',
    fieldApiName: BILLING_STATE_CODE_FIELD
  })
  wiredStates({ data }) {
      if (!data) {
          return;
      }

      // Create a mapping of country number to country code
      // It is an object where the key is the number, the value is the code
      // It is just data.controllerValues but flipped
      const validForToCountry = Object.fromEntries(Object.entries(data.controllerValues).map(([key, value]) => [value, key]));

      this._countryToStates = data.values.reduce((accumulatedStates, state) => {
        // Takes the country number and converts it into the proper country code using the validForToCountry mapping defined above
        const countryIsoCode = validForToCountry[state.validFor[0]];

        // Now use the country code to group the state objects together by country
        // This returns an object of arrays where each item in the array is a state object in that country
        // Each state object contains the name of the state, the country number, and the state code
        return { ...accumulatedStates, [countryIsoCode]: [...(accumulatedStates?.[countryIsoCode] || []), state] };
      }, {});
  }

  get countries() {
      return this._countries;
  }

  get states() {
      return this._countryToStates[this.selectedCountry] || [];
  }

  handleCountry(event) {
      this.selectedCountry = event.detail.value;
  }

  handleState(event) {
      this.selectedState = event.detail.value;
  }

  connectedCallback() {
    // this.loadCountries();
    this.dispatchEvent(new RefreshEvent());
  }

  //actions

  actions = {
    'accountClone': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_CLONE_PAGE) {

        console.log('Actions : accountClone:: ' + ctx.currentPage);

        // Activate Session Based Permission

          activateSessionPermSet() ;

         // Activate Session Based Permission

      }
    },
    'accountResults': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_RESULTS_PAGE) {

        console.log('Actions : accountResults:: ' + ctx.currentPage);

        this.accNameDisabled=false;
        this.accTypeDisabled=false;
        this.accPhoneDisabled=true;
        this.accDunsDisabled=false;
        this.accWebsiteDisabled = false;
        this.accStreetDisabled = true;
        this.accCountryDisabled = false;
        this.accCityDisabled=true;
        this.accStateDisabled=true;
        this.accZipDisabled=true;
        this.leadCurrencyDisabled=true;

        this.accSeachBtnDisabled=false;


      }
    },
    'accountEnrich': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_ENRICH_PAGE) {/* call dnb match api */
        console.log('In Actions accountEnrich');
        this.showSpinner = true;
        getMatchResults({ accEnrichString: this.accString })

          .then(result => {
            this.showSpinner = false;
            console.log('getMatchResults data:: ' + result);
            console.log('getMatchResults:: ' + JSON.stringify(result));

            result.length === 0 ? this.isAccountEnrichtableEmpty = true : this.isAccountEnrichtableEmpty = false;

            this.accountEnrichResults = result;

          })
          .catch(error => {

            this.showSpinner = false;
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
              message = error.body.map(e => e?.message).join(', ');
            } else if (typeof error.body?.message === 'string') {
              message = error.body.message;
            }
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error while searching Account records !',
                message: message,
                variant: 'error',
                mode: 'sticky'
              }),
            );
          });

            // Disable Fields
            // this.leadFnameDisabled=true;
            // this.leadLnameDisabled=true;
            // this.leadEmailDisabled=true;
            // this.leadPhoneDisabled=true;
            // this.leadCompanyDisabled = false;
            // this.leadWebsiteDisabled = false;
            // this.leadDunsDisabled = false;
            // this.leadCountryDisabled=false;
            // this.leadStreetDisabled=true;
            // this.leadCityDisabled=true;
            // this.leadStateDisabled=true;
            // this.leadPostalDisabled=true;
            // this.leadSourceDisabled=true;
            // this.leadIndustryDisabled=true;
            // this.leadSeachBtnDisabled=false;

      }
    }
  };

  //actions

  // handleOnLoad(event) {
  //   console.log('RecordTypeId1: '+this.recordTypeId);
  //   event.preventDefault();
  //   // this.handleSearch();
  // }

  closeModal() {

    const closeModalEvent = new CustomEvent('modalclose');
    this.dispatchEvent(closeModalEvent);
  }

  validateSearchForm() {
    // Check required fields
    let isValid = true;
    let inputFields = this.template.querySelectorAll("lightning-record-edit-form[data-id='accountSearch'] lightning-input-field,lightning-combobox");

    inputFields.forEach(inputField => {
        if (!inputField.reportValidity()) {
            isValid = false;
        }
    });
    return isValid;
  }

  // Reset Search Form
  resetSearchForm() {
    const inputFields = this.template.querySelectorAll('lightning-input-field');
    if (inputFields) {
      inputFields.forEach(inputField => {
        inputField.reset();
      });
    }

    const selectFields = this.template.querySelectorAll('lightning-combobox');
    selectFields.forEach(element => {
        element.value = 'Temp';
        element.setCustomValidity('');
        element.reportValidity();
        element.value = undefined;
    })
    this.accountResults = [];
    this.accountEnrichResults = [];
    this.selectedAccountIdRow = [];
    this.currentPage = this.ACCOUNT_RESULTS_PAGE;
  }

  handleSearch() {
    this.showSpinner = true;
    this.createDisabled = false;
    this.currentPage=this.ACCOUNT_RESULTS_PAGE;
    // Check required fields before submission
    if (!this.validateSearchForm()) {
      this.showSpinner = false;
      return;
    }

    // const sfields = this.template.querySelectorAll("lightning-input-field");
    const sfields = this.template.querySelectorAll("lightning-record-edit-form[data-id='accountSearch'] lightning-input-field,lightning-combobox");
    const fieldVals = {};

    if (sfields) {
      sfields.forEach((field) => {

        if (field.fieldName == this.nameField.fieldApiName) {
          fieldVals[this.nameField.fieldApiName] = field.value;
        }
        // SFDC-20955
        // else if (field.fieldName == this.typefield.fieldApiName) {

        //   fieldVals[this.typefield.fieldApiName] = field.value;
        // }
        // else if (field.name == this.countryField.fieldApiName) {

        //   fieldVals[this.countryField.fieldApiName] = field.value;
        // }
         // SFDC-20955
        else if (field.name == 'Country') {
          fieldVals[this.countryCodeField.fieldApiName] = field.value;
        }
        else if (field.fieldName == this.websiteField.fieldApiName) {
          fieldVals[this.websiteField.fieldApiName] = field.value;
        }
        else if (field.fieldName == this.dunsField.fieldApiName) {
          fieldVals[this.dunsField.fieldApiName] = field.value;
        }
      });
    }

    this.accObject = fieldVals;
    this.accString = JSON.stringify(fieldVals);
    this.accountResults = null;
    this.acctbtndisabled = true;

    console.log('fieldVals = ' + JSON.stringify(fieldVals));

    findAccountSBCByName({ accString: JSON.stringify(fieldVals) })

      .then(result => {
        this.showSpinner = false;
        result.length === 0 ? this.isAccounttableEmpty = true : this.isAccounttableEmpty = false;
        let tempList = [];

        result.forEach((record) => {
          let rec = Object.assign({}, record);
          tempList.push(rec);
        });

        this.accountResults = tempList;

      })
      .catch(error => {

        this.showSpinner = false;
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
          message = error.body.map(e => e?.message).join(', ');
        } else if (typeof error.body?.message === 'string') {
          message = error.body.message;
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error while searching Account records !',
            message: message,
            variant: 'error',
            mode: 'sticky'
          }),
        );
      });
  }

  selectAccount(event) {
    this.selectedAccount = event.detail.selectedRows;
    this.selectedAccount = event.detail.selectedRows[0];
    if (this.acctbtndisabled) this.acctbtndisabled = false;

    this.selectedAccountId = event.detail.selectedRows[0].Id;
    this.selectedAccountName = event.detail.selectedRows[0].Name;
    this.selectedAccountIdRow = this.selectedAccount.length ? [this.selectedAccount.Id] : [];

    if (this.currentPage == 'accountEnrich') {
      this.creationSourceAudit = 'Enriched';
      this.isEnriched = true;
    }
    this.selectedAccount = {...this.selectedAccount, Creation_Source_Audit__c: this.creationSourceAudit};

    console.log('this.selectedAccount--- ' + JSON.stringify(this.selectedAccount));
    this.assignValues(this.selectedAccount);
  }

  handleRowActions(event) {
    const actionName = event.detail.action.label;
    const row = event.detail.row;
    this.originalAcc = row;
    if (this.originalAcc && this.originalAcc.Id) {
    //  delete this.originalAcc.Id;
      delete this.originalAcc.AccountName;
    }
    console.log('this.originalAcc--- ' + JSON.stringify(this.originalAcc));
    this.selectedAccount = this.originalAcc;
    this.pageHistoryArray.push(this.currentPage);
    const nextPage = this.ACCOUNT_CLONE_PAGE;
    let updatedFields;
    switch (actionName) {
      case 'Clone - Business Group':
        updatedFields = [...this.accountCloneFields, {
          fieldName: 'Type',
          value: this.selectedAccount.Type
        }];
        break;

      case 'Clone - Status':
        updatedFields = [...this.accountCloneFields, {
          fieldName: 'Status__c',
          value: this.selectedAccount.Status__c
        }];
        break;

      case 'Clone':
        this.resetSelectedFields();
        break;

      default:
        console.error('Unexpected action:', actionName);
        break;
    }
    if (updatedFields) {
      this.accountCloneFields = updatedFields;
      this.removeFieldFromOptions(updatedFields[0].fieldName);
    }

    this.currentPage = nextPage;

    if (this.actions.hasOwnProperty(this.currentPage)) {
      console.log('Account Clone Action');
      this.actions[this.currentPage](this);
    }
  }

  removeFieldFromOptions(fieldName) {
    this.accountCloneFieldOptions = this.accountCloneFieldOptions.filter(item => item !== fieldName);
  }

  addCloneFieldHandler(event) {
    const selectedField = event.detail.value;
    this.accountCloneFields.push({
      fieldName: selectedField,
      value: this.selectedAccount[selectedField] || ''
    });

    this.accountCloneFieldOptions = this.accountCloneFieldOptions.filter(item => item !== selectedField);
  }
  resetSelectedFields() {
    this.accountCloneFields = [];
    this.accountCloneFieldOptions = Object.keys(this.CLONE_FIELD_MAPPINGS);
  }

  // handleRowActions(event) {
  //   const actionName = event.detail.action.name;
  //   const row = event.detail.row;
  //   this.originalAcc = row;

  //   this.assignValues(this.originalAcc);

  //   this.pageHistoryArray.push(this.currentPage);
  //   const nextPage = this.ACCOUNT_CREATE_PAGE;

  //   switch (actionName) {
  //     case 'cloneMSPAccReqd':
  //       this.Type = 'End User - MSP';
  //       this.disabledFields.Type = true;
  //       break;
  //     case 'cloneMSPBoomerang':
  //       this.accountType = 'Domestic Ultimate';

  //       break;
  //     case 'cloneMSPAggConv':
  //       this.accountType = 'End User - Sonian';
  //       break;
  //   }
  //   this.currentPage = nextPage;
  // }

  cleanUpStateName(stateName) {

    const accentMap = {
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n', 'ü': 'u', // Add more mappings as needed
        'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ñ': 'N', 'Ü': 'U'  // Include uppercase characters
    };

    if (!stateName) {
      return "";
    }

    // Use regex to replace accented characters with their base Latin counterparts
    return stateName.replace(/[áéíóúñüÁÉÍÓÚÑÜ]/g, char => accentMap[char] || char);
  }

  getValidStateCode(stateName, stateCode) {
    // Retrieve the list of states for the currently selected country
    const currentCountryStateList = this._countryToStates[this.selectedCountry];

    // Step 1: Check if stateCode matches any state value directly
    if (stateCode) {
        const stateObjectByCode = currentCountryStateList.find(state => {
            return state.value.toLowerCase() === stateCode.toLowerCase();
        });
        if (stateObjectByCode) {
            // If a state code match is found, return the corresponding state value
            console.log('Found stateObjectByCode valid state code = ' + stateObjectByCode.value);
            return stateObjectByCode.value;
        }
    }

    // Step 2: Lookup state value by state label (case-insensitive)
    if (stateName) {
        const stateObjectByName = currentCountryStateList.find(state => {
            return state.label.toLowerCase() === stateName.toLowerCase();
        });
        if (stateObjectByName) {
            // If a state name match is found, return the corresponding state value
            console.log('Found stateObjectByName valid state code = ' + stateObjectByName.value);
            return stateObjectByName.value;
        }
    }

    // Step 3: If no direct match is found, try cleaning up the state name and searching again
    if (stateName) {
        const cleanedStateName = this.cleanUpStateName(stateName);
        console.log('cleanedStateName = ' + cleanedStateName);
        const stateObjectByCleanedName = currentCountryStateList.find(state => {
            return state.label.toLowerCase() === cleanedStateName.toLowerCase();
        });
        if (stateObjectByCleanedName) {
            // If a match is found with the cleaned-up state name, return the corresponding state value
            console.log('Found stateObjectByCleanedName valid state code = ' + stateObjectByCleanedName.value);
            return stateObjectByCleanedName.value;
        }
    }

    // Return an empty string if no match is found
    return "";
  }

  assignValues(obj) {
    this.accountname = obj ? obj.Name : "";
    this.Type = obj ? obj.Type : "";
    this.address = obj ? obj.BillingAddress : "";
    this.street = obj ? obj.BillingStreet : "";
    this.city = obj ? obj.BillingCity : "";
    this.country = obj ? obj.BillingCountry : "";
    this.selectedState = obj ? this.getValidStateCode(obj.BillingState, obj.BillingStateCode) : "";
    this.zip = obj ? obj.BillingPostalCode : "";
    this.website = obj ? obj.Website : "";
    this.phone = obj ? obj.Phone : "";
    this.dunsnum = obj ? obj.D_B_DUNS_Number__c : "";
    this.currency = obj ? obj.AccountCurrency1__c : "";
    this.busgroup = obj ? obj.BusinessGroup__c : "";
    this.parentid = obj ? obj.ParentId : "";
    this.employeecount = obj ? obj.NumberOfEmployees : "";
    this.industry = obj ? obj.Industry : "";
  }

  handleAddressFieldChange(event) {
    if (this.isEnriched) {
      this.creationSourceAudit = 'Enriched - Overridden';
    }
  }

  navigateToPrevious(event) {

    this.assignValues();
    this.disabledFields = {};
    this.selectedAccount = null;
    if (this.currentPage == this.ACCOUNT_ENRICH_PAGE) {
      this.accountEnrichResults = [];
    }
    this.currentPage = this.pageHistoryArray.pop();
    console.log('this.currentPage:: ' + this.currentPage);

    if (this.currentPage != 'accountClone') {
      this.resetSelectedFields();
    }

    if (this.actions.hasOwnProperty(this.currentPage)) {
      console.log('Executes Action');
      this.actions[this.currentPage](this);
    }
  }

  navigateToPage(event) {

    this.pageHistoryArray.push(this.currentPage);
    const nextPage = event.target.getAttribute('data-next-page');
    this.currentPage = nextPage;
    if(nextPage == this.ACCOUNT_CREATE_PAGE && this.selectedAccount == null){
      this.assignValues(this.accObject);
    }

    if (this.actions.hasOwnProperty(this.currentPage)) {
      console.log('Executes Action');
      this.actions[this.currentPage](this);
    }

    // if (nextPage == this.ACCOUNT_ENRICH_PAGE) {

    //   this.showSpinner = true;

    //   getMatchResults({ accEnrichString: this.accString })

    //     .then(result => {
    //       this.showSpinner = false;
    //       let tempList = [];
    //       result.length === 0 ? this.isAccountEnrichtableEmpty = true : this.isAccountEnrichtableEmpty = false;

    //       result.forEach((record) => {
    //         let rec = Object.assign({}, record);
    //         rec.AccountName = '/' + rec.Id;
    //         tempList.push(rec);
    //       });

    //       this.accountEnrichResults = tempList;

    //     })
    //     .catch(error => {

    //       this.showSpinner = false;
    //       let message = 'Unknown error';
    //       if (Array.isArray(error.body)) {
    //         message = error.body.map(e => e.message).join(', ');
    //       } else if (typeof error.body.message === 'string') {
    //         message = error.body.message;
    //       }
    //       this.dispatchEvent(
    //         new ShowToastEvent({
    //           title: 'Error while searching Account records !',
    //           message: message,
    //           variant: 'error',
    //           mode: 'sticky'
    //         }),
    //       );
    //     });
    // }
  }

  navigateToRecord(event) {
    let recId = this.selectedAccountId;
    if(this.currentPage == this.ACCOUNT_CREATE_PAGE ){
      recId = this.navRecId;
    }else if(this.currentPage == this.ACCOUNT_CLONE_PAGE){
      recId = this.navRecId;
    }
    this.recordPageRef = {
      type: 'standard__recordPage',
      attributes: {
        recordId: recId,
        actionName: 'view',
      },
    };
    this.resetSearchForm();
    this[NavigationMixin.Navigate](this.recordPageRef);
  }

  navigateToAccount(){
    this.resetSearchForm();
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Account",
        actionName: "home"
      }
    });
  }

  onHandleSort(event) {
    this.template.querySelector('lightning-datatable').selectedRows = [];
    this.acctbtndisabled = true;
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.accountResults];
    cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
    this.accountResults = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  sortBy(field, reverse, primer) {
    const key = primer
      ? function (x) {
        return primer(x[field]);
      }
      : function (x) {
        return x[field];
      };

    return function (a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  }

  validateAccountForm() {
    // Check required fields
    let isValid = true;
    let inputFields = this.template.querySelectorAll('lightning-input-field[data-id=' + this.ACCOUNT_FORM_ID + ']');

    inputFields.forEach(inputField => {
        if (!inputField.reportValidity()) {
            isValid = false;
        }
    });
    return isValid;
  }

  handleNewRecord(event){

    const dataId = event.target.getAttribute('data-form-id');
    console.log('handleNewRecord:: data-form-id = ' + dataId);

    if (dataId === this.ACCOUNT_FORM_ID) {
      // Check required fields before submission
      if (!this.validateAccountForm()) {
        return;
      }
    }

    this.showSpinner = true;

    const formFields = this.template.querySelectorAll('lightning-input-field[data-id=' + this.ACCOUNT_FORM_ID + '],lightning-combobox');
    const fieldVals = {};

    if (formFields) {
      formFields.forEach((field) => {
        if (field.name == 'Country') {
          fieldVals[this.countryCodeField.fieldApiName] = field.value;
        } else if (field.name == 'State') {
          fieldVals[this.stateCodeField.fieldApiName] = field.value;
        } else {
          fieldVals[field.fieldName] = field.value;
        }
      });
    }
    if(this.recordTypeId){
      fieldVals["RecordTypeId"] = this.recordTypeId;
    }
    const newAcc = JSON.stringify(fieldVals);
    console.log('fieldVals = ' + newAcc);
      CreateAccount({ newAccountString: newAcc, originalAccString: JSON.stringify(this.originalAcc)})

      .then(result => {
        console.log('Result String  :: ' + JSON.stringify(result));
        this.navRecId = result;
        this.navigateToRecord(event);
        this.showSpinner = false;
      })
      .catch(error => {
        this.showSpinner = false;
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
          message = error.body.map(e => e?.message).join(', ');
        } else if (typeof error.body?.message === 'string') {
          message = error.body.message;
        }
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error Creating Account!',
            message: message,
            variant: 'error',
            mode: 'sticky'
          }),
        );
      });

    }




    // handleCountry(event) {
    //   this.selectedCountryCode = event.detail.value;
    //   this.countrycode = event.detail.value;
    //   console.log('handleCountry Code  :: ' + this.countrycode);
    //   var selectedCountry = this.selectedLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
    //   console.log('handleCountry Country  :: ' + selectedCountry);
    //   this.country = selectedCountry;
    //   let myArr ;
    //   if (this.accString && this.isValidJSON(this.accString)) {
    //     myArr = JSON.parse(this.accString);
    //   } else {
    //       myArr = {};
    //   }
    //   myArr.CountryCode = this.countrycode;
    //   myArr.Country = selectedCountry;
    //   myArr.BillingCountry = selectedCountry;
    //   this.accString = JSON.stringify(myArr);
    //   console.log('handleCountry AccString  :: ' + this.accString);
    // }
    // isValidJSON(str) {
    //   try {
    //       JSON.parse(str);
    //       return true;
    //   } catch (e) {
    //       return false;
    //   }
    // }

  //For Country Picklist
    // loadCountries() {
    //   getCountryList()
    //     .then((result) => {
    //       let options = [];
    //       var cont = JSON.parse(result);
    //       console.log('This Country List:: ' + JSON.stringify(cont));
    //       for (var key in cont) {
    //         options.push({ label: key, value: cont[key] });
    //       }
    //       this.countries = options.sort((a, b) => a.label.localeCompare(b.label));
    //       this.selectedCountryCode = 'US';
    //       // console.log('This options:: ' + options);
    //     })
    //     .catch((error) => {

    //       let message = 'Unknown error';
    //       if (Array.isArray(error.body)) {
    //         message = error.body.map(e => e?.message).join(', ');
    //       } else if (typeof error.body?.message === 'string') {
    //         message = error.body.message;
    //       }
    //       this.dispatchEvent(
    //         new ShowToastEvent({
    //           title: 'Error Fetching Countries !',
    //           message: message,
    //           variant: 'error',
    //           mode: 'sticky'
    //         }),
    //       );

    //     });
    // }
}