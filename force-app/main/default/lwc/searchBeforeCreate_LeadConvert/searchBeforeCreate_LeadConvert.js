import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import COUNTRY_CODE_FIELD from '@salesforce/schema/Account.BillingCountryCode';
import BILLING_STATE_CODE_FIELD from '@salesforce/schema/Account.BillingStateCode';
import LEAD_OBJECT from '@salesforce/schema/Lead';
import FIRSTNAME_FIELD from '@salesforce/schema/Lead.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Lead.LastName';
import EMAIL_FIELD from '@salesforce/schema/Lead.Email';
import PHONE_FIELD from '@salesforce/schema/Lead.Phone';
import COMPANY_FIELD from '@salesforce/schema/Lead.Company';
import WEBSITE_FIELD from '@salesforce/schema/Lead.Website';
import DUNS_FIELD from '@salesforce/schema/Lead.D_B_DUNS_Number__c';
import ADDRESS_FIELD from '@salesforce/schema/Lead.Address';
import COUNTRYCODE_FIELD from '@salesforce/schema/Lead.CountryCode';
import CURRENCY_FIELD from '@salesforce/schema/Lead.CurrencyIsoCode';
import LEADSOURCE_FIELD from '@salesforce/schema/Lead.LeadSource';
import COUNTRY_FIELD from '@salesforce/schema/Lead.Country';
import STREET_FIELD from '@salesforce/schema/Lead.Street';
import CITY_FIELD from '@salesforce/schema/Lead.City';
import STATECODE_FIELD from '@salesforce/schema/Lead.StateCode';
import STATE_FIELD from '@salesforce/schema/Lead.State';
import POSTALCODE_FIELD from '@salesforce/schema/Lead.PostalCode';
import INDUSTRY from '@salesforce/schema/Lead.Industry';
import NOOFEMPLOYEES from '@salesforce/schema/Lead.NumberOfEmployees';
import OWNER_IS_USER_FIELD from '@salesforce/schema/Lead.Owner_Is_User__c';
import USER_ID from '@salesforce/user/Id';
import findAccountByName from '@salesforce/apex/searchBeforeCreateController.findAccountByName';
import getMatchResults from '@salesforce/apex/searchBeforeCreateController.getMatchResults';
import getDnBDataBlocksInfo from '@salesforce/apex/searchBeforeCreateController.getDnBDataBlocksInfo';
import getOpportunities from '@salesforce/apex/searchBeforeCreateController.getOpportunities'; // For Opportunity Result Page -- Aditya
//import convertLeadDML from '@salesforce/apex/searchBeforeCreateController.convertLeadDML';
import convertLead from '@salesforce/apex/searchBeforeCreateController.convertLead';
import getContactsByEmail from '@salesforce/apex/searchBeforeCreateController.getContactsByEmail';
// import getCountryList from '@salesforce/apex/searchBeforeCreateController.getCountryList';
import activateSessionPermSet from '@salesforce/apex/searchBeforeCreateController.activateSessionPermSet';
import deactivateSessionPermSet from '@salesforce/apex/searchBeforeCreateController.deactivateSessionPermSet';
import getRecordTypeId from '@salesforce/apex/searchBeforeCreateController.getRecordTypeId';
import { CloseActionScreenEvent } from 'lightning/actions';
//import getAccountRecordTypes from '@salesforce/apex/searchBeforeCreateController.getAccountRecordTypes';

//Account Actions
const ACCOUNT_ACTIONS = [
  { label: 'Clone - Business Group', fields: ['Type'] },
  { label: 'Clone - Status', fields: ['Status'] },
  { label: 'Clone', fields: [] }
];

// Account Columns
const ACC_COLUMNS = [
  {
    label: 'Name', fieldName: 'AccountLink', type: 'url', initialWidth: 160, sortable: true, typeAttributes: {
      label: { fieldName: 'AccountName' },
      tooltip: { fieldName: 'AccountName' },
      target: '_blank'
    }
  },
  { label: 'Website', fieldName: 'Website', type: 'url', initialWidth: 160, sortable: true },
  { label: 'Alt. Name', fieldName: 'Alternative_Account_Name__c', initialWidth: 100, sortable: true },
  { label: 'Type', fieldName: 'Type', initialWidth: 100, sortable: true },
  { label: 'Group', fieldName: 'BusinessGroup__c', initialWidth: 80, sortable: true },
  { label: 'Country', fieldName: 'BillingCountry', initialWidth: 100, sortable: true },
  { label: 'State/Province', fieldName: 'BillingState', initialWidth: 100, sortable: true },
  { label: 'City', fieldName: 'BillingCity', initialWidth: 100, sortable: true },
  { label: 'ARR', fieldName: 'ARR__c', type: 'currency', initialWidth: 80, sortable: true },
  { label: 'Currency', fieldName: 'CurrencyIsoCode', initialWidth: 80, sortable: true },
  {
    type: 'action',
    typeAttributes: {
      rowActions: ACCOUNT_ACTIONS
    }
  }

];

// Account Enrich Columns
const ACC_ENRICH_COLUMNS = [
  { label: 'Name', fieldName: 'Name', initialWidth: 160, sortable: true },
  { label: 'Website', fieldName: 'Website', type: 'url', initialWidth: 160, sortable: true },
  { label: 'Corporate Linkage', fieldName: 'Description', initialWidth: 160, sortable: true },
  { label: 'Duns', fieldName: 'D_B_DUNS_Number__c', initialWidth: 100, sortable: true },
  { label: 'Country', fieldName: 'BillingCountry', initialWidth: 100, sortable: true },
  { label: 'State/Province', fieldName: 'BillingState', initialWidth: 100, sortable: true },
  { label: 'City', fieldName: 'BillingCity', initialWidth: 100, sortable: true },
  { label: 'Confidence Code', fieldName: 'DNBConnect__D_B_Match_Confidence_Code__c', initialWidth: 80, sortable: true }
];

// Contact Columns
const CON_COLUMNS = [
  {
    label: 'Name', fieldName: 'ContactName', type: 'url', sortable: true, typeAttributes: {
      label: { fieldName: 'Name' },
      tooltip: { fieldName: 'Name' },
      target: '_blank'
    }
  },
  {
    label: 'Account Name', fieldName: 'AccountLink', type: 'url', sortable: true, typeAttributes: {
      label: { fieldName: 'AccountName' },
      tooltip: { fieldName: 'AccountName' },
      target: '_blank'
    }
  },
  { label: 'Email', fieldName: 'Email', type: 'Email', sortable: true, },
  { label: 'Mailing Country Code', fieldName: 'MailingCountryCode', sortable: true, }
];


// Opportunity Columns
const OPP_COLUMNS = [
  {
    label: 'Opportunity Name', fieldName: 'OpportunityName', type: 'url', sortable: true,
    typeAttributes: {
      label: { fieldName: 'Name' },
      tooltip: { fieldName: 'Name' },
      target: '_blank'
    }
  },
  {
    label: 'Account Name', fieldName: 'AccUrl', type: 'url', sortable: true,
    typeAttributes: {
      label: { fieldName: 'accountName' },
      tooltip: { fieldName: 'accountName' },
      target: '_blank',
    }
  },
  {
    label: 'Owner Full Name', fieldName: 'OwnerUrl', type: 'url', sortable: true,
    typeAttributes: {
      label: { fieldName: 'ownerName' },
      tooltip: { fieldName: 'ownerName' },
      target: '_blank',
    }
  },
  { label: 'Business Group', fieldName: 'Business_Group__c', sortable: true },
  { label: 'Most Recent Product of Interest', fieldName: 'Primary_Product_Family_2__c', sortable: true },
  { label: 'Close Date', fieldName: 'CloseDate', type: 'date', sortable: true, sortDirection: 'desc' },
  { label: 'Stage Name', fieldName: 'StageName', sortable: true },
  { label: 'Amount', fieldName: 'Amount', type: 'currency', sortable: true }
];
// Opportunity Columns

export default class SearchBeforeCreate_LeadConvert extends NavigationMixin(LightningElement) {

  @api
  leadId;

  _countries = [];
  _countryToStates = {};
  selectedCountry;
  selectedState;

  objectApiName = LEAD_OBJECT;
  firstnameField = FIRSTNAME_FIELD;
  lastameField = LASTNAME_FIELD;
  emailField = EMAIL_FIELD;
  phoneField = PHONE_FIELD;
  companyField = COMPANY_FIELD;
  websiteField = WEBSITE_FIELD;
  dunsField = DUNS_FIELD;
  addressField = ADDRESS_FIELD;
  countrycodeField = COUNTRYCODE_FIELD;
  leadCurrecyFirld = CURRENCY_FIELD;
  leadsourceField = LEADSOURCE_FIELD;
  countryField = COUNTRY_FIELD;
  streetField = STREET_FIELD;
  cityField = CITY_FIELD;
  statecodeField = STATECODE_FIELD;
  postalcodeField = POSTALCODE_FIELD;
  industryField = INDUSTRY;
  employeeCountField = NOOFEMPLOYEES;
  stateField = STATE_FIELD;
  ownerIsUserField = OWNER_IS_USER_FIELD;

  leadFnameDisabled=false;
  leadLnameDisabled=false;
  leadEmailDisabled=false;
  leadPhoneDisabled=false;
  leadCompanyDisabled = false;
  leadWebsiteDisabled = false;
  leadDunsDisabled = false;
  leadCountryDisabled=false;
  leadStreetDisabled=false;
  leadCityDisabled=false;
  leadStateDisabled=false;
  leadPostalDisabled=false;
  leadSourceDisabled=false;
  leadIndustryDisabled=false;
  leadSeachBtnDisabled=false;
  @track accTypeOptions = [];

  @wire(CurrentPageReference)
  currentPageReference;

  // Page Section
  titleString = 'Convert Lead';
  superTitleString = 'Lead';
  showSpinner = false;

  // Page Section

  // Accounts Section

  ACCOUNT_COLUMNS = ACC_COLUMNS;
  DEFAULT_PAGE = 'ACCOUNT_RESULTS_PAGE';
  ACCOUNT_RESULTS_PAGE = 'accountResults';
  ACCOUNT_ENRICH_PAGE = 'accountEnrich';
  ACCOUNT_CREATE_PAGE = 'accountCreate';
  ACCOUNT_PAGE_HEADER = 'Select an Existing Account';

  @track accountResults = [];
  @track selectedAccount;
  @track sortDirection = 'desc';
  // defaultSortDirection = 'desc';
  @track sortedBy;//= 'ARR__c';

  acctbtndisabled = true;
  isAccounttableEmpty = false;
  // Accounts Section
  //Account Clone Section
  ACCOUNT_CLONE_PAGE = 'accountClone';
  ACCOUNT_CLONE_PAGE_HEADER = 'Account Information';
  ACCOUNT_CLONE_ID = 'clone-account';
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

  //Account Clone Section

  //  Accounts Enrichment Section
  ENRICH_COLUMNS = ACC_ENRICH_COLUMNS;
  ACCOUNT_ENRICH_HEADER = 'Select an Account from D&B';
  ACCOUNT_ENRICH_PAGE = 'accountEnrich';
  @track accountEnrichResults = [];
  isAccountEnrichtableEmpty = false;
  //  Accounts Enrichment Section

  // Contacts Section

  CONTACT_RESULTS_PAGE = 'contactResults';
  CONTACT_CREATION_PAGE = 'contactCreate';
  CONTACT_PAGE_HEADER = 'Select an Existing Contact';
  CONTACT_COLUMNS = CON_COLUMNS;
  @track contactResults = [];
  selectedContact;
  contbtndisabled = true;
  pageHistoryArray = [];
  isContacttableEmpty = false;

  // Contacts Section

  //For Opportunity Page Start ---Aditya
  OPPORTUNITY_COLUMN = OPP_COLUMNS;
  OPPORTUNITY_RESULTS_PAGE = 'opportunityResults';
  OPP_CREATION_PAGE = 'OppCreate';
  OPPORTUNITY_PAGE_HEADER = 'Select an Existing New Business Opportunity';
  @track opportunityResults = [];
  selectedOpportunity;
  isFinishDisabled = true;
  OPP_TYPE_SELECTED = 'selected';
  OPP_TYPE_NONE = 'none';
  @api selectedAccountId;
  @track selectedOpportunityId = [];
  @track selectedAccountIdRow = [];
  @track selectedContactId = [];
  @track showOpportunityIconDiv;
  isOpptytableEmpty = false;

  //@track doNotCreateOpportunityButtonVariant = 'brand';

  // Lead Search

   LEAD_SEARCH_ID = 'lead-search';

  // Lead Search

  //For Opportunity Result Page

  // New Contact Page
  CONTACT_CREATION_PAGE = 'contactCreate';
  CONTACT_CREATION_HEADER = 'Contact Information';
  CONTACT_FORM_ID = 'new-contact';
  // New Contact Page

  //New Opportunity Page
  OPPORTUNITY_FORM_ID = 'new-opportunity';
  OPPORTUNITY_CREATION_HEADER = 'Opportunity Information'
  @api selectedAccountName;
  //New Opportunity Page

  //New Account Page
  ACCOUNT_CREATE_PAGE = 'accountCreate';
  ACCOUNT_CREATION_HEADER = 'Account Information';
  ACCOUNT_FORM_ID = 'new-account';
  ACCOUNT_ENRICH_INFORMATION_PAGE = 'accountInformation';
  DNB_ACCOUNT_SELECTED = 'dnbAccountSelected';
  dnbAccType;
  isdnbAccSelected;
  //New Account Page

  //For Confirmation Page
  CONFIRM_PAGE = 'confirmationResults';
  getAccountName;
  getAccountURL;
  getContactName;
  getContactURL;
  getOppName;
  getOppURL;
  isShowConfirmationPage = false;
  isConvertLeadSuccessful = true;
  @api confirmAccountId;
  @api confirmContactId;
  @api confirmOpportunityId;
  @track isEnriched = false;
  //For Confirmation Page

  @api
  currentPage = this.ACCOUNT_RESULTS_PAGE;
  // Init Lead Load Section
  lead;
  email;
  website;
  duns;
  company;
  countrycode;

  fname;
  lname;
  currency;
  phone;
  country;
  leadsource;
  state;
  street;
  city;
  zip;
  leadMapForAccount;
  accountObj;
  accString;
  status = 'Prospect';
  employeeCount;
  dnbEmployeeCount;
  @track dnbIndustry;
  @track industry;
  billingState;
  billingStateCode;
  accType;

  accountOwner = USER_ID;
  @track recordTypeId;
  accountName;
  @track websiteOrEmailDomain;
  @track accountRecordTypes;
  recordTypeOptions = [];
  @track selectedRecordTypeId;
  _recordData;
  @track creationSourceAudit = 'Manual';
  @track disableDeselectButton = true;
  @track dataTableId;
  disabledFields = {
    Name: false,
    Phone: false,
    D_B_DUNS_Number__c: true,
    Type: false,
    Website: false,
    NumberOfEmployees: true,
    CurrencyIsoCode: false,
    Industry: true,
    Contact_Email: true,
    Contact_Currency: true,
    Contact_LeadSource: true
  };
  @api
  get recordData() {
    return this._recordData;
  }
  set recordData(record) {
    console.log('recordData:: ' + JSON.stringify(record));
    if (!record) return;
    this.accountName = record.Name || '';
    this.duns = record.D_B_DUNS_Number__c || '';
    // this.accType = record.Type || 'Prospect';
    this.accType = record.Type || '';   // 'Prospect' is deactivated
    this.website = record.Website || '';
    this.employeeCount = record.NumberOfEmployees || '';
    this.currency = record.CurrencyIsoCode || '';
    this.industry = record.Industry || '';
    this.street = record.BillingStreet || '';
    this.country = record.BillingCountry || '';
    this.city = record.BillingCity || '';
    this.billingState = record.BillingState || '';
    this.billingStateCode = record.BillingStateCode || '';
    this.zip = record.BillingPostalCode || '';
  }
  get showTitleString() {
    return this.isShowConfirmationPage ? '' : this.titleString;
  }

  get showSuperTitleString() {
    return this.isShowConfirmationPage ? '' : this.superTitleString;
  }

  get getOpportunityName() {
    console.log('getOpportunityName:: ' + this.selectedAccountName);
    return `${this.selectedAccountName} - `;
  }
  get getIndustryName() {
    console.log('getIndustryName:: ' + this.industry);
    return this.industry;
  }


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

  //actions

  actions = {
    'accountEnrich': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_ENRICH_PAGE) {/* call dnb match api */
        console.log('In Actions accountEnrich');
        console.log('this.accString:: '+ this.accString);
        this.showSpinner = true;
        this.isdnbAccSelected=false;

        getMatchResults({ accEnrichString: this.accString })
          .then(result => {
            var selectedAccountEnrichIdInList = false;
            this.showSpinner = false;
            //console.log('getMatchResults data:: ' + result);
            console.log('getMatchResults:: ' + JSON.stringify(result));

            result.length === 0 ? this.isAccountEnrichtableEmpty = true : this.isAccountEnrichtableEmpty = false;

            this.accountEnrichResults = result;

            result.forEach((record) => {
              let rec = Object.assign({}, record);
              if(rec.D_B_DUNS_Number__c === this.selectedAccountIdRow[0]){
                selectedAccountEnrichIdInList = true;
              }

              if(selectedAccountEnrichIdInList){
                this.acctbtndisabled = false;
              }else{
                this.acctbtndisabled = true;
              }
            });

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

            // this.template.querySelectorAll('lightning-input-field').forEach(item=>{
            //   item.disabled=true;
            // });

            this.leadFnameDisabled=true;
            this.leadLnameDisabled=true;
            this.leadEmailDisabled=true;
            this.leadPhoneDisabled=true;
            this.leadCompanyDisabled = false;
            this.leadWebsiteDisabled = false;
            this.leadDunsDisabled = false;
            this.leadCountryDisabled=false;
            this.leadStreetDisabled=true;
            this.leadCityDisabled=true;
            this.leadStateDisabled=true;
            this.leadPostalDisabled=true;
            this.leadSourceDisabled=true;
            this.leadIndustryDisabled=true;
            this.leadSeachBtnDisabled=false;

        //   this.template.querySelectorAll('lightning-combobox').forEach(item=>{
        //     item.disabled=false;
        //  });


            // Disable Fields

      }
    },

    'accountCreate': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_CREATE_PAGE) {

        console.log('call dnb datablocks api');
        this.showSpinner = true;

        let selectedAccountduns = this.selectedAccount?.["D_B_DUNS_Number__c"];

        console.log('DnB Selected Account Duns::' + selectedAccountduns);

        if (this.dnbAccType == 'dnbAccountSelected'){

          this.isdnbAccSelected=true;
          console.log('this.isdnbAccSelected ::  ' + this.isdnbAccSelected);
        }

        // if (this.dnbAccType == 'dnbAccountSelected') {
        if (this.isdnbAccSelected == true) {
          getDnBDataBlocksInfo({ duns: selectedAccountduns })

            .then(result => {
              this.showSpinner = false;
              console.log('getDnBDataBlocksInfo :: ' + result);
              console.log('getDnBDataBlocksInfo:: ' + JSON.stringify(result));
              const res = JSON.stringify(result);
              const parseRes = JSON.parse((res));
              console.log('parseRes :: ' + parseRes);
              this.dnbEmployeeCount = parseRes.NumberOfEmployees;
              this.dnbIndustry = parseRes.Industry;
              this.industry = this.dnbIndustry;
              console.log('NumberofEmployees :: ' + parseRes.NumberOfEmployees);
              console.log('dnbIndustry :: ' + this.dnbIndustry);
              console.log('this.industry :: ' + this.industry);
              if (this.selectedAccount !== null && this.selectedAccount !== undefined && Object.keys(this.selectedAccount).length > 0) {
                if (!('NoOfEmployees' in this.selectedAccount) && !('Industry' in this.selectedAccount)) {
                  const updatedSelectedDnBAccount = {
                    ...this.selectedAccount,
                    Industry: this.dnbIndustry,
                    NumberOfEmployees: this.dnbEmployeeCount
                  };
                  this.recordData = updatedSelectedDnBAccount;
                  console.log('Record Data Account Create Actions :: ' + JSON.stringify(updatedSelectedDnBAccount));
                }
              }

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
        } else {
          this.showSpinner = false;
          this.recordData = { ...this.accountObj };
          this.creationSourceAudit = 'Manual - Lead Conversion';
        }

        this.leadFnameDisabled=true;
        this.leadLnameDisabled=true;
        this.leadEmailDisabled=true;
        this.leadPhoneDisabled=true;
        this.leadCompanyDisabled = true;
        this.leadWebsiteDisabled = true;
        this.leadDunsDisabled = true;
        this.leadCountryDisabled=true;
        this.leadStreetDisabled=true;
        this.leadCityDisabled=true;
        this.leadStateDisabled=true;
        this.leadPostalDisabled=true;
        this.leadSourceDisabled=true;
        this.leadIndustryDisabled=true;
        this.leadSeachBtnDisabled=true;
      }
    },

    'accountResults': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_RESULTS_PAGE) {
      console.log('Actions : accountResults:: ' + ctx.currentPage);

      this.leadFnameDisabled=true;
      this.leadLnameDisabled=true;
      this.leadEmailDisabled=true;
      this.leadPhoneDisabled=true;
      this.leadCompanyDisabled = false;
      this.leadWebsiteDisabled = false;
      this.leadDunsDisabled = false;
      this.leadCountryDisabled=false;
      this.leadStreetDisabled=true;
      this.leadCityDisabled=true;
      this.leadStateDisabled=true;
      this.leadPostalDisabled=true;
      this.leadSourceDisabled=true;
      this.leadIndustryDisabled=true;
      this.leadSeachBtnDisabled=false;
      }
    },

    'accountClone': (ctx) => {
      if (ctx.currentPage == this.ACCOUNT_CLONE_PAGE) {
        console.log('Actions : accountClone:: ' + ctx.currentPage);
        // Activate Session Based Permission
          activateSessionPermSet() ;
      }
    },

    'contactResults': (ctx) => {
      if (ctx.currentPage == this.CONTACT_RESULTS_PAGE) {
        console.log('Actions : contactResults');

        getContactsByEmail({ emailString: this.email })
          .then(result => {
            console.log('this.CONTACT_RESULTS_PAGE, getContactsByEmail result=', JSON.stringify(result));
            this.showSpinner = false;

            result.length === 0 ? this.isContacttableEmpty = true : this.isContacttableEmpty = false;

            let tempList = [];

            result.forEach((record) => {
              let rec = Object.assign({}, record);
              rec.ContactName = '/' + rec.Id;
              rec.AccountLink = (rec.Account === undefined ? '' : '/' + rec.Account.Id);
              rec.AccountName = (rec.Account === undefined ? '' : rec.Account.Name);
              tempList.push(rec);
            });

            this.contactResults = tempList;
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
                title: 'Error while searching Contact records !',
                message: message,
                variant: 'error',
                mode: 'sticky'
              }),
            );
          });

          this.leadFnameDisabled=true;
          this.leadLnameDisabled=true;
          this.leadEmailDisabled=false;
          this.leadPhoneDisabled=true;
          this.leadCompanyDisabled = true;
          this.leadWebsiteDisabled = true;
          this.leadDunsDisabled = true;
          this.leadCountryDisabled=true;
          this.leadStreetDisabled=true;
          this.leadCityDisabled=true;
          this.leadStateDisabled=true;
          this.leadPostalDisabled=true;
          this.leadSourceDisabled=true;
          this.leadIndustryDisabled=true;
          this.leadSeachBtnDisabled=false;
      }
    },

    'contactCreate': (ctx) => {
          if (ctx.currentPage == this.CONTACT_CREATION_PAGE) {
            console.log('Actions : contactCreate');

            this.leadFnameDisabled=true;
            this.leadLnameDisabled=true;
            this.leadEmailDisabled=true;
            this.leadPhoneDisabled=true;
            this.leadCompanyDisabled = true;
            this.leadWebsiteDisabled = true;
            this.leadDunsDisabled = true;
            this.leadCountryDisabled=true;
            this.leadStreetDisabled=true;
            this.leadCityDisabled=true;
            this.leadStateDisabled=true;
            this.leadPostalDisabled=true;
            this.leadSourceDisabled=true;
            this.leadIndustryDisabled=true;
            this.leadSeachBtnDisabled=true;
      }
    },

    'opportunityResults': (ctx) => {
      if (ctx.currentPage == this.OPPORTUNITY_RESULTS_PAGE) {
        console.log('Actions : opportunityResults:: ' + ctx.currentPage);

        getOpportunities({ accountId: this.selectedAccountId })
          .then(result => {
            this.showSpinner = false;
            console.log('this.OPPORTUNITY_RESULTS_PAGE, getOpportunities');
            if (result) {
              console.log('result len = ' + result.length);
              console.log('result = ' + JSON.stringify(result));
            }

            result.length === 0 ? this.isOpptytableEmpty = true : this.isOpptytableEmpty = false;

            this.opportunityResults = result.map(opp => {
              let newOpp = { ...opp };
              newOpp.OpportunityName = '/' + opp.Id;
              newOpp.AccUrl = '/' + opp.Account.Id;
              newOpp.OwnerUrl = '/' + opp.Owner.Id;
              newOpp.accountName = opp.Account.Name;
              newOpp.ownerName = opp.Owner.Name;
              return newOpp;
            });
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
                title: 'Error while searching Opportunity records!',
                message: message,
                variant: 'error',
                mode: 'sticky'
              }),
            );
          });
      }

      this.leadFnameDisabled=true;
      this.leadLnameDisabled=true;
      this.leadEmailDisabled=true;
      this.leadPhoneDisabled=true;
      this.leadCompanyDisabled = true;
      this.leadWebsiteDisabled = true;
      this.leadDunsDisabled = true;
      this.leadCountryDisabled=true;
      this.leadStreetDisabled=true;
      this.leadCityDisabled=true;
      this.leadStateDisabled=true;
      this.leadPostalDisabled=true;
      this.leadSourceDisabled=true;
      this.leadIndustryDisabled=true;
      this.leadSeachBtnDisabled=true;
    },

    'OppCreate': (ctx) => {
      if (ctx.currentPage == this.OPP_CREATION_PAGE) {
        console.log('Actions : OppCreate:: ' + ctx.currentPage);

        this.leadFnameDisabled=true;
        this.leadLnameDisabled=true;
        this.leadEmailDisabled=true;
        this.leadPhoneDisabled=true;
        this.leadCompanyDisabled = true;
        this.leadWebsiteDisabled = true;
        this.leadDunsDisabled = true;
        this.leadCountryDisabled=true;
        this.leadStreetDisabled=true;
        this.leadCityDisabled=true;
        this.leadStateDisabled=true;
        this.leadPostalDisabled=true;
        this.leadSourceDisabled=true;
        this.leadIndustryDisabled=true;
        this.leadSeachBtnDisabled=true;
      }
    }
  };

  //actions

  handleChange(event) {
    this.selectedRecordTypeId = event.detail.value;
    console.log("selectedRecordTypeId: " + this.selectedRecordTypeId);
  }

  @wire(getRecord, {
    recordId: '$leadId',
    // fields: [EMAIL_FIELD, WEBSITE_FIELD, DUNS_FIELD, COMPANY_FIELD,COUNTRYCODE_FIELD,COUNTRY_FIELD] })
    fields: [EMAIL_FIELD, WEBSITE_FIELD, DUNS_FIELD, COMPANY_FIELD, COUNTRYCODE_FIELD, CURRENCY_FIELD, COUNTRY_FIELD,
      FIRSTNAME_FIELD, LASTNAME_FIELD, PHONE_FIELD, LEADSOURCE_FIELD, STREET_FIELD, STATECODE_FIELD, CITY_FIELD,
      POSTALCODE_FIELD, INDUSTRY, NOOFEMPLOYEES, STATE_FIELD, OWNER_IS_USER_FIELD]
  })
  wiredleadRecord({ error, data }) {
    if (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error loading lead',
          message: error?.body?.message,
          variant: 'error',
          mode: 'sticky'
        }),
      );
    } else if (data) {
      this.lead = data;
      this.email = getFieldValue(this.lead, EMAIL_FIELD);
      this.website = getFieldValue(this.lead, WEBSITE_FIELD);
      this.duns = getFieldValue(this.lead, DUNS_FIELD);
      this.company = getFieldValue(this.lead, COMPANY_FIELD);
      this.countrycode = getFieldValue(this.lead, COUNTRYCODE_FIELD);
      this.country = getFieldValue(this.lead, COUNTRY_FIELD);
      this.fname = getFieldValue(this.lead, FIRSTNAME_FIELD);
      this.lname = getFieldValue(this.lead, LASTNAME_FIELD);
      this.currency = getFieldValue(this.lead, CURRENCY_FIELD);
      this.phone = getFieldValue(this.lead, PHONE_FIELD);
      this.leadsource = getFieldValue(this.lead, LEADSOURCE_FIELD);
      this.stateCode = getFieldValue(this.lead, STATECODE_FIELD);
      this.street = getFieldValue(this.lead, STREET_FIELD);
      this.city = getFieldValue(this.lead, CITY_FIELD);
      this.zip = getFieldValue(this.lead, POSTALCODE_FIELD);
      this.industry = getFieldValue(this.lead, INDUSTRY);
      this.employeeCount = getFieldValue(this.lead, NOOFEMPLOYEES);
      this.billingState = getFieldValue(this.lead, STATE_FIELD);
      this.ownerIsUser = getFieldValue(this.lead, OWNER_IS_USER_FIELD);

      console.log('Lead Duns Number:: ' + this.duns);
      console.log('Lead Employee COunt:: ' + this.employeeCount);

      if (this.ownerIsUser === false) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error: No permission to convert lead',
            message: 'You have to be the owner to convert this lead.',
            variant: 'error',
            mode: 'sticky'
          }),
        );
        this.closeModal();
      }

      this.websiteOrEmailDomain = (() => {
        const emailDomain = this.email?.split('@')[1]?.replace(".invalid","");
        return this.website ?? emailDomain;
      })();

      this.accountObj = {
        Website: (this.website === '' || this.website === null) ? this.websiteOrEmailDomain : this.website,
        D_B_DUNS_Number__c: this.duns,
        Company: this.company,
        Name: this.company,
        CountryCode: this.countrycode,
        Country: this.country,
        CurrencyIsoCode: this.currency,
        BillingCity: this.city,
        BillingCountry: this.country,
        BillingState: this.billingState,
        BillingStateCode: this.stateCode,
        BillingStreet: this.street,
        BillingPostalCode: this.zip,
        Industry: this.industry,
        NumberOfEmployees: this.employeeCount
      };
      this.accString = JSON.stringify(this.accountObj);
      console.log('wiredleadRecord, AccountObj:: ' + JSON.stringify(this.accountObj));
      this.selectedCountry = this.countrycode;
      // this.loadCountries();
      this.getLeadRecordTypeId();
    }
  }
  getLeadRecordTypeId() {
    getRecordTypeId({ leadId: this.leadId })
        .then(result => {
          console.log('getLeadRecordTypeId() recordtypeId:: ' + result);
            this.recordTypeId = result;
        })
        .catch(error => {
          let message = 'Unknown error';
          if (Array.isArray(error.body)) {
            message = error.body.map(e => e?.message).join(', ');
          } else if (typeof error.body?.message === 'string') {
            message = error.body.message;
          }
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error while assigning record type !',
              message: message,
              variant: 'error',
              mode: 'sticky'
            }),
          );
        });
    }

  // Init Lead Load Section

  handleOnLoad(event) {

    event.preventDefault();

    this.leadFnameDisabled=true;
    this.leadLnameDisabled=true;
    this.leadEmailDisabled=true;
    this.leadPhoneDisabled=true;
    this.leadCompanyDisabled = false;
    this.leadWebsiteDisabled = false;
    this.leadDunsDisabled = false;
    this.leadCountryDisabled=false;
    this.leadStreetDisabled=true;
    this.leadCityDisabled=true;
    this.leadStateDisabled=true;
    this.leadPostalDisabled=true;
    this.leadSourceDisabled=true;
    this.leadIndustryDisabled=true;
    this.leadSeachBtnDisabled=false;

    // this.handleSearch();
  }

  // handleClose(event){
  //   this.dispatchEvent(new CloseActionScreenEvent());

  // }

  closeModal() {
    const closeModalEvent = new CustomEvent('modalclose');
      // DeActivate Session Based Permission
      deactivateSessionPermSet();
    this.dispatchEvent(closeModalEvent);
  }

  validateSearchForm() {
    // Check required fields
    let isValid = true;
    let inputFields = this.template.querySelectorAll("lightning-record-edit-form[data-id='leadSearch'] lightning-input-field,lightning-combobox");

    inputFields.forEach(inputField => {
        if (!inputField.reportValidity()) {
            isValid = false;
        }
    });
    return isValid;
  }

  handleSearch() {

    console.log('handleSearch::' + this.currentPage);
    this.showSpinner = true;

    // Check required fields before submission
    if (!this.validateSearchForm()) {
      this.showSpinner = false;
      return;
    }

    //this.acctbtndisabled = true;
    //this.accountResults = null;

    const sfields = this.template.querySelectorAll("lightning-record-edit-form[data-id='leadSearch'] lightning-input-field,lightning-combobox");
    const fieldVals = {};

    if (sfields) {
      sfields.forEach((field) => {
        if (field.fieldName == this.companyField.fieldApiName) {
          fieldVals[this.companyField.fieldApiName] = field.value;
          fieldVals["Name"] = field.value;
        }
        else if (field.name == this.countryField.fieldApiName) {
          fieldVals[this.countryField.fieldApiName] = field.value;
          fieldVals["BillingCountryCode"] = field.value;
        }
        else if (field.fieldName == this.websiteField.fieldApiName) {
          fieldVals[this.websiteField.fieldApiName] = field.value;
        }
        else if (field.fieldName == this.dunsField.fieldApiName) {
          fieldVals[this.dunsField.fieldApiName] = field.value;
        }
        // else if (field.fieldName == this.emailField.fieldApiName) {
        //   fieldVals[this.emailField.fieldApiName] = field.value;
        // }
      });
    }

    this.accObject = fieldVals;
    this.accString = JSON.stringify(fieldVals);
    this.accountResults = null;
    this.acctbtndisabled = true;

    console.log('handleSearch:: fieldVals = ' + JSON.stringify(fieldVals));

    switch (this.currentPage) {

      case this.ACCOUNT_RESULTS_PAGE:

        this.accountResults = null;
        if(this.selectedAccountIdRow.length>0) {this.acctbtndisabled = false;} else{this.acctbtndisabled = true;}
        console.log('handleSearch currentPage::' + this.currentPage);

        findAccountByName({ accString: JSON.stringify(fieldVals) })

          .then(result => {
            this.showSpinner = false;

            result.length === 0 ? this.isAccounttableEmpty = true : this.isAccounttableEmpty = false;

            console.log('handleSearch(), this.ACCOUNT_RESULTS_PAGE, findAccountByName result=', result);
            let tempList = [];
            //VP added this logic to fix error 3
            var selectedAccountIdInList = false;

            result.forEach((record) => {
              let rec = Object.assign({}, record);
              //rec.AccountName = '/' + rec.Id;
              rec.AccountLink = (rec.Id === undefined ? '' : '/' + rec.Id);
              rec.AccountName = (rec.Name === undefined ? '' : rec.Name);
              tempList.push(rec);
              if(rec.Id === this.selectedAccountIdRow[0]){
                selectedAccountIdInList = true;
              }
            });

            //this.accountResults = tempList;
            this.accountResults = this.sortByARR(tempList);
            if(!selectedAccountIdInList){
              this.selectedAccountIdRow = [];
              this.acctbtndisabled = true;
            }else{
              this.acctbtndisabled = false;
            }

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

        break;

      case this.CONTACT_RESULTS_PAGE:
        console.log('handleSearch currentPage::' + this.currentPage);

        getContactsByEmail({ emailString: fieldVals[this.emailField.fieldApiName] })

          .then(result => {
            console.log('handleSearch(), this.CONTACT_RESULTS_PAGE, getContactsByEmail result=', result);
            this.showSpinner = false;

            result.length === 0 ? this.isContacttableEmpty = true : this.isContacttableEmpty = false;

            let tempList = [];

            result.forEach((record) => {
              let rec = Object.assign({}, record);
              rec.ContactName = '/' + rec.Id;
              rec.AccountLink = (rec.Account === undefined ? '' : '/' + rec.Account.Id);
              rec.AccountName = (rec.Account === undefined ? '' : rec.Account.Name);
              tempList.push(rec);
            });

            this.contactResults = tempList;

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
                title: 'Error while searching Contact records !',
                message: message,
                variant: 'error',
                mode: 'sticky'
              }),
            );
          });
        break;

      case this.OPPORTUNITY_RESULTS_PAGE:
        console.log('handleSearch currentPage::' + this.currentPage);
        break;
      case this.CONFIRM_PAGE:
        console.log('handleSearch currentPage::' + this.currentPage);
        break;

      case this.ACCOUNT_ENRICH_PAGE:
        console.log('handleSearch currentPage::' + this.currentPage);
        this.currentPage=this.ACCOUNT_RESULTS_PAGE;
        this.accountResults = null;
        this.acctbtndisabled = true;

        console.log('enrich fieldvals:: ' + JSON.stringify(fieldVals));
        console.log('enrich accString:: ' + this.accString);

        const myArr = JSON.parse(this.accString);
        myArr.Company=fieldVals.Company;
        myArr.D_B_DUNS_Number__c=fieldVals.D_B_DUNS_Number__c;

        this.accString = JSON.stringify(myArr);
        console.log('new enrich accString:: ' + this.accString);

        findAccountByName({ accString: JSON.stringify(fieldVals) })

          .then(result => {
            this.showSpinner = false;

            result.length === 0 ? this.isAccounttableEmpty = true : this.isAccounttableEmpty = false;

            console.log('handleSearch(), this.ACCOUNT_ENRICH_PAGE, findAccountByName result=', result);
            let tempList = [];

            result.forEach((record) => {
              let rec = Object.assign({}, record);
              //rec.AccountName = '/' + rec.Id;
              rec.AccountLink = (rec.Id === undefined ? '' : '/' + rec.Id);
              rec.AccountName = (rec.Name === undefined ? '' : rec.Name);
              tempList.push(rec);
            });

            //this.accountResults = tempList;
            this.accountResults = this.sortByARR(tempList);

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

          //this.navigateToPrevious(null);
    }

  }



  selectExistingAccount(event) {

    console.log('Selected:: ' + JSON.stringify(event.detail.selectedRows));
    console.log('CurrentPageSelectedAccount:: ' + this.currentPage);

    this.selectedAccount = event.detail.selectedRows;
    this.selectedAccount = event.detail.selectedRows[0];
    if (this.acctbtndisabled) this.acctbtndisabled = false;
    //For Opportunity Result Page
    this.selectedAccountId = event.detail.selectedRows[0].Id;
    this.selectedAccountName = event.detail.selectedRows[0].Name;
    this.selectedAccountIdRow = [this.selectedAccount.Id ? this.selectedAccount.Id : this.selectedAccount.D_B_DUNS_Number__c];
    this.disableDeselectButton = this.selectedAccount.length === 0;
    this.dataTableId = event.target.getAttribute('data-id');
    console.log('dataTableId:: ' + this.dataTableId);
    console.log('selectedAccountIdRow:: ' + this.selectedAccountIdRow);
    if (this.currentPage == 'accountEnrich') {
      this.creationSourceAudit = 'Enriched';
      this.isEnriched = true;
    }
    this.selectedAccount = {...this.selectedAccount, Creation_Source_Audit__c: this.creationSourceAudit};
    console.log('selectedAccount:: ' + JSON.stringify(this.selectedAccount));
    this.assignValues(this.selectedAccount);
  }

  selectExistingContact(event) {

    console.log('Selected:: ' + JSON.stringify(event.detail.selectedRows));
    this.selectedContact = event.detail.selectedRows[0];
    console.log('selectedContact:: ' + JSON.stringify(this.selectedContact));
    if (this.contbtndisabled) this.contbtndisabled = false;
    this.selectedContactId = this.selectedContact.length ? [this.selectedContact.Id] : [];
    console.log('selectedContactId:: ' + JSON.stringify(this.selectedContactId));
    this.disableDeselectButton = this.selectedContact.length === 0;
    this.dataTableId = event.target.getAttribute('data-id');
    console.log('dataTableId:: ' + this.dataTableId);


  }

  selectExistingOpportunity(event) {
    console.log('Selected:: ' + JSON.stringify(event.detail.selectedRows));
    this.selectedOpportunity = event.detail.selectedRows[0];
    console.log('selectedOpportunity:: ' + JSON.stringify(this.selectedOpportunity));
    if (this.isFinishDisabled) this.isFinishDisabled = false;
    this.selectedOpportunityId = this.selectedOpportunity.length ? [this.selectedOpportunity.Id] : [];
    this.disableDeselectButton = this.selectedOpportunity.length === 0;
    this.dataTableId = event.target.getAttribute('data-id');
    console.log('dataTableId:: ' + this.dataTableId);
  }

  navigateToPrevious(event) {

    this.assignValues();
    this.currentPage = this.pageHistoryArray.pop();
    console.log('navigateToPrevious:: this.currentPage:: ' + this.currentPage);
    if (this.currentPage == 'accountEnrich' || this.currentPage == 'accountCreate') {
      this.selectedAccount = {};
      this.selectedAccountIdRow = [];
      this.acctbtndisabled = true;
      this.dnbAccType = null;
    }
    if(this.currentPage == 'accountResults'){
      var selectedAccountFound = false;
      this.accountResults.forEach((record) => {
        let rec = Object.assign({}, record);
        if(rec.Id === this.selectedAccountIdRow[0]){
          selectedAccountFound = true;
        }
      });
      if(selectedAccountFound){
        this.acctbtndisabled = false;
      }else{
        this.acctbtndisabled = true;
      }
      console.log('navigateToPrevious::accountResultsPage this.accountResults ----  ' + JSON.stringify(this.accountResults));
    }
    if (this.currentPage != 'accountClone') {
      // Clear out accountCloneFields & accountCloneFieldOptions
      this.resetSelectedFields();
    }
    if (this.actions.hasOwnProperty(this.currentPage)) {
      console.log('Executes Action');
      this.actions[this.currentPage](this);
    }
  }

  navigateToPage(event) {

    this.pageHistoryArray.push(this.currentPage);
    this.dnbAccType = event.target.getAttribute('data-acc-type');
    const nextPage = event.target.getAttribute('data-next-page');
    this.currentPage = nextPage;
    if(nextPage == this.ACCOUNT_CREATE_PAGE && this.selectedAccount == null){
      this.assignValues(this.accountObj);
    }
    console.log('nextPage: ' + nextPage);
    console.log('hasOwnProperty:: ' + this.actions.hasOwnProperty(this.currentPage));
    if (this.actions.hasOwnProperty(this.currentPage)) {
      console.log('Executes Action');
      this.actions[this.currentPage](this);
    }
    this.acctbtndisabled = true;
  }

  navigateToRecord(event) {
    this.recordPageRef = {
      type: 'standard__recordPage',
      attributes: {
        recordId: this.leadId,
        actionName: 'view',
      },
    };
    this[NavigationMixin.Navigate](this.recordPageRef);
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

  handleNewRecord(event) {

    const dataId = event.target.getAttribute('data-form-id');

    if (dataId === this.ACCOUNT_FORM_ID) {
      // Check required fields before submission
      if (!this.validateAccountForm()) {
        return;
      }
    }

    console.log('dataId:: ' + dataId)
    const form = Array.from(this.template.querySelectorAll('lightning-input-field[data-id=' + dataId + ']'));
    // const form = Array.from(this.template.querySelectorAll('lightning-input-field[data-id=' + dataId + '],lightning-combobox'));

    const newformVals = form.reduce((fvals, f) => {
      return { ...fvals, ...{ [f.fieldName]: f.value } }
    }, {})

    console.log('newformVals::' + JSON.stringify(newformVals));

    switch (dataId) {


      // To be Uncommented and used for New Account and New Opportunity

      case this.ACCOUNT_FORM_ID:
        newformVals["RecordTypeId"] = this.recordTypeId;
        newformVals["Status__c"] = this.status;
        newformVals["BillingCountryCode"] = this.selectedCountry;
        newformVals["BillingStateCode"] = this.selectedState;
        this.selectedAccount = newformVals;
        this.selectedAccountName = newformVals.Name;
        console.log('selectedAccount after account Create::' + JSON.stringify(this.selectedAccount));
        break;

      case this.CONTACT_FORM_ID:
        newformVals["Contact_Status__c"] = 'Active';
        newformVals["MailingCountryCode"] = this.selectedCountry;
        newformVals["MailingStateCode"] = this.selectedState;
        this.selectedContact = newformVals;
        console.log('selectedContact::' + JSON.stringify(this.selectedContact));
        break;

      case this.OPPORTUNITY_FORM_ID:
        this.selectedOpportunity = newformVals;
        console.log('selectedOpportunity::' + JSON.stringify(this.selectedOpportunity));
        this._convertLead(JSON.stringify(this.selectedAccount), JSON.stringify(this.originalAcc), JSON.stringify(this.selectedContact), JSON.stringify(this.selectedOpportunity), false, this.leadId);
        break;

      case this.ACCOUNT_CLONE_ID:
        newformVals["RecordTypeId"] = this.recordTypeId;
        this.selectedAccount = { ...this.selectedAccount, ...newformVals };
        this.selectedAccountName = this.selectedAccount.Name;
        console.log('selectedAccount after account Clone::' + JSON.stringify(this.selectedAccount));
        break;

    }

    this.navigateToPage(event);

  }

  sortByARR(accountData) {
    return accountData.sort((a, b) => {
      let aVal = a.ARR__c;
      let bVal = b.ARR__c;

      // Check for null or empty values for a
      let aIsNull = aVal === null || aVal === '' || typeof aVal === 'undefined';

      // Check for null or empty values for b
      let bIsNull = bVal === null || bVal === '' || typeof bVal === 'undefined';

      if (aIsNull && bIsNull) return 0;  // Both are null or empty, they are equal in terms of sorting
      if (aIsNull) return 1;  // a is null or empty, so it should come after
      if (bIsNull) return -1;  // b is null or empty, so it should come after

      return bVal - aVal;  // Regular numeric sort for non-null and non-empty values
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
      // Handle null values for all fields
      if (a == null || a === '') return 1;
      if (b == null || b === '') return -1;

      return reverse * ((a > b) - (b > a));
    };
  }

  // @track countries = [];
  // @track selectedCountryCode = '';

  // handleCountry(event) {
  //   this.selectedCountryCode = event.detail.value;
  // this.countrycode = event.detail.value;
  //   console.log('handleCountry Code  :: ' + this.countrycode);
  //   var selectedCountry = this.selectedLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
  //   console.log('handleCountry Country  :: ' + selectedCountry);
  //   //VP: I don't understand this logic - was causing an error when fixing error 3
  //   /*const myArr = JSON.parse(this.accString);
  //   myArr.CountryCode = this.countrycode;
  //   myArr.Country = selectedCountry;
  //   myArr.BillingCountry = selectedCountry;
  //   this.accString = JSON.stringify(myArr);
  //   console.log('handleCountry AccString  :: ' + this.accString);*/
  // }



  // loadCountries() {
  //   getCountryList()
  //     .then((result) => {
  //       let options = [];
  //       var cont = JSON.parse(result);
  //       //console.log('This Country List:: ' + JSON.stringify(cont));
  //       for (var key in cont) {

  //         //console.log('Countries Key :: ' + key);
  //         //console.log('Countries Value :: ' + cont[key]);
  //         options.push({ label: key, value: cont[key] });
  //       }
  //       this.countries = options.sort((a, b) => a.label.localeCompare(b.label));;
  //       this.selectedCountryCode = this.countrycode;
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



  // Account Results
  @wire(findAccountByName, { accString: '$accString' })
  wiredAccounts({ error, data }) {
    this.showSpinner = true;
    if (data) {
      console.log('@wire(findAccountByName):: ' + JSON.stringify(data));
      this.showSpinner = false;

      data.length === 0 ? this.isAccounttableEmpty = true : this.isAccounttableEmpty = false;

      let tempList = [];
      data.forEach((record) => {
        let rec = Object.assign({}, record);
        //rec.AccountName = '/' + rec.Id;
        //rec.AccountLink = '/' + rec.Id;
        //rec.AccountName = rec.Name;
        rec.AccountLink = (rec.Id === undefined ? '' : '/' + rec.Id);
        rec.AccountName = (rec.Name === undefined ? '' : rec.Name);
        console.log('rec.Name = ', rec.Name);
        tempList.push(rec);
      });

      //this.accountResults = tempList;
      this.accountResults = this.sortByARR(tempList);
      this.error = undefined;

    } else if (error) {
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
    }
  }

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

  navigateToFinish(event) {
    const oppType = event.target.getAttribute('data-opp-type');
    if (oppType === this.OPP_TYPE_SELECTED) {
      this.showOpportunityIconDiv = false;
      this._convertLead(JSON.stringify(this.selectedAccount), JSON.stringify(this.originalAcc), JSON.stringify(this.selectedContact), JSON.stringify(this.selectedOpportunity), 'flase', this.leadId);
      this.navigateToPage(event);
    } else if (oppType === this.OPP_TYPE_NONE) {
      this.showOpportunityIconDiv = true;
      this._convertLead(JSON.stringify(this.selectedAccount), JSON.stringify(this.originalAcc), JSON.stringify(this.selectedContact), null, 'true', this.leadId);
      this.navigateToPage(event);
    }
  }

  _convertLead(selectedAccount, originalAcc, selectedContact, selectedOpportunity, doNotCreateOpportunity, leadId) {
    //this.handleRemoveClass();
    this.showSpinner = true;
    this.showContainer = false;
    this.isShowConfirmationPage = true;
    let accountData = selectedAccount;
    let contactData = selectedContact;
    let opportunityData = selectedOpportunity;
    console.log('accountData:' + accountData);
    console.log('contactData:' + contactData);
    console.log('opportunityData:' + opportunityData);
    let leadData = leadId;
    console.log('leadId:' + leadData);
    if (this.selectedAccount != null && this.selectedContact != null && (this.selectedOpportunity != null || doNotCreateOpportunity != null || opportunityName != null)) {
      convertLead({ leadId: leadData, account: accountData, originalAccount: originalAcc, contact: contactData, opportunity: opportunityData, donotCreateOpp: doNotCreateOpportunity })
        .then(result => {
          // Handle successful conversion.
          this.isConvertLeadSuccessful = true;
          let response = JSON.parse(result);
          console.log('response:' + JSON.stringify(response));
          this.confirmAccountId = response.accountId;
          this.confirmContactId = response.contactId;
          this.confirmOpportunityId = doNotCreateOpportunity != 'false' ? response.opportunityId : '';
          this.getAccountName = response.accountName;
          this.getContactName = response.contactName;
          this.getOppName = doNotCreateOpportunity != 'false' ? response.opportunityName : '';
          this.showSpinner = false;
        })
        .catch(error => {
          this.showSpinner = false;
          this.isConvertLeadSuccessful = false;
          let message = 'Unknown error';
          if (Array.isArray(error.body)) {
            message = error.body.map(e => e?.message).join(', ');
          } else if (typeof error.body?.message === 'string') {
            message = error.body.message;
          }
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error Converting Lead !',
              message: message,
              variant: 'error',
              mode: 'sticky'
            }),
          );
        });
      /*try{
        const result = await convertLeadDML({
        opportunityId: OpportunityId,
        doNotCreateOpportunity: doNotCreateOpportunity,
        opportunityName: opportunityName
        });
        if (OpportunityId) {

        } else {

        }
      } catch (error) {
            this.dispatchEvent(
              new ShowToastEvent({
              title: 'Error',
              message: 'An error occured while performing DML',
              variant: 'error'
              })
            );
      } finally {
      this.showSpinner = false;
      }*/
    }
  }
  //For Opportunity Page
  /*handleRemoveClass() {
    this.dispatchEvent(new CustomEvent('classremove'));
  }*/
  navigateToAccount(event) {
    event.preventDefault();
    console.log('confirmAccountId:: ' + this.confirmAccountId);
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.confirmAccountId,
        actionName: 'view'
      }
    });
  }

  navigateToContact(event) {
    event.preventDefault();
    console.log('confirmContactId:: ' + this.confirmContactId);
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.confirmContactId,
        actionName: 'view'
      }
    });
  }

  navigateToOpportunity(event) {
    event.preventDefault();
    console.log('confirmOpportunityId:: ' + this.confirmOpportunityId);
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.confirmOpportunityId,
        actionName: 'view'
      }
    });
  }

  handleRowActions(event) {
    const actionName = event.detail.action.label;
    const row = event.detail.row;
    this.originalAcc = row;
    //VP I don't get this code, this will display the Account Id if user clicks previous
    /*if (this.originalAcc && this.originalAcc.Id) {
      delete this.originalAcc.AccountName;
    }*/
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

  handleDeselect() {
     //const dataTable = this.template.querySelector(`lightning-datatable[data-id="${this.dataTableId}"]`);
     const dataTable = this.template.querySelector('lightning-datatable[data-id="accountDataTable"]');
     console.log('DataTable', JSON.stringify(dataTable));
     if (dataTable) {
        dataTable.selectedRows = [];
        // const dataIdValue = dataTable.getAttribute('data-id');
        // console.log('data-id Value:', dataIdValue);
        // const selectedRows = dataTable.getSelectedRows();
        //  console.log('Selected Rows:', selectedRows);

        //  if (selectedRows && selectedRows.length > 0) {
        //       const selectedRow = selectedRows[0];
        //      console.log('Selected Row Data:', selectedRow);
        //      dataTable.selectedRows = [];
        //  }
     }
    // var dataTable = this.template.querySelector('lightning-datatable[data-id=' + this.dataTableId + ']');
    // if (dataTable) {
    //         // var selectedRows = dataTable.getSelectedRows();
    //         // if (selectedRows && selectedRows.length > 0) {
    //           dataTable.selectedRows = [];
    //           this.selectedAccountIdRow = [];
    //         //}
    //       }
    this.disableDeselectButton = true;
    this.acctbtndisabled = true;
    this.contbtndisabled = true;
  }

}