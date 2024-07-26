import { LightningElement, api, wire, track } from "lwc";
import { createRecord, getRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRelatedContacts from "@salesforce/apex/OpportunityAddressSelectorController.getRelatedContacts";

import ACCOUNTID_FIELD from "@salesforce/schema/Opportunity.AccountId";
import DISTIRIBUTOR_ID_FIELD from "@salesforce/schema/Opportunity.Distributor__c";
import RESELLER_ID_FIELD from "@salesforce/schema/Opportunity.Reseller__c";
import SHIPCON_FIELD from "@salesforce/schema/Opportunity.Shipping_Contact__c";
import GROUP_FIELD from "@salesforce/schema/Opportunity.Business_Group__c";
import ACCOUNTPHONE_FIELD from "@salesforce/schema/Opportunity.Account.Phone";
import ACCOUNTBILLINGCOUNTRY_FIELD from "@salesforce/schema/Opportunity.Account.BillingCountry";
import PRIMARYQUOTE_FIELD from "@salesforce/schema/Opportunity.SBQQ__PrimaryQuote__c";

import QUOTE_ACCOUNTID_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__c";
import QUOTE_DISTIRIBUTOR_ID_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Distributor__c";
import QUOTE_RESELLER_ID_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBCF_Reseller__c";
import QUOTE_SHIPCON_FIELD from "@salesforce/schema/SBQQ__Quote__c.Shipping_Contact__c";
import QUOTE_GROUP_FIELD from "@salesforce/schema/SBQQ__Quote__c.Business_Group__c";
import QUOTE_ACCOUNTPHONE_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__r.Phone";
import QUOTE_ACCOUNTBILLINGCOUNTRY_FIELD from "@salesforce/schema/SBQQ__Quote__c.SBQQ__Account__r.BillingCountry";

const OPP_FIELDS = [
  ACCOUNTID_FIELD,
  DISTIRIBUTOR_ID_FIELD,
  RESELLER_ID_FIELD,
  SHIPCON_FIELD,
  GROUP_FIELD,
  ACCOUNTPHONE_FIELD,
  ACCOUNTBILLINGCOUNTRY_FIELD,
  PRIMARYQUOTE_FIELD
];

const QUOTE_FIELDS = [
  QUOTE_ACCOUNTID_FIELD,
  QUOTE_DISTIRIBUTOR_ID_FIELD,
  QUOTE_RESELLER_ID_FIELD,
  QUOTE_SHIPCON_FIELD,
  QUOTE_GROUP_FIELD,
  QUOTE_ACCOUNTPHONE_FIELD,
  QUOTE_ACCOUNTBILLINGCOUNTRY_FIELD
];

const CON_COLUMNS = [
  {
    label: "Name",
    fieldName: "ContactName",
    type: "url",
    sortable: true,
    typeAttributes: {
      label: { fieldName: "Name" },
      tooltip: { fieldName: "Name" },
      target: "_blank"
    }
  },

  { label: "Email", fieldName: "Email", type: "Email", sortable: true },
  { label: "Phone Number", fieldName: "Phone", sortable: true },
  {
    label: "Account Name",
    fieldName: "AccountLink",
    type: "url",
    sortable: true,
    typeAttributes: {
      label: { fieldName: "AccountName" },
      tooltip: { fieldName: "AccountName" },
      target: "_blank"
    }
  },
  { label: "Contact Type", fieldName: "Contact_Type__c", sortable: true },
  {
    label: "MSP End Customer",
    fieldName: "MSP_End_Customer__c",
    sortable: true,
    type: "boolean"
  }
];

const CON_SORT_OVERRIDE = {
  ContactName: "Name",
  AccountLink: "AccountName"
};

const DEFAULT_SHIP_TO_SOURCE = "account";

export default class ShippingContact extends LightningElement {
  @api recordId;
  @api objectName;
  accountId;
  accountPhone;
  accountBillingCountry;
  CONTACT_COLUMNS = CON_COLUMNS;
  @track shippingContact;
  @track contactResults = [];
  @track selectedContactId = [];
  selectedContact;
  @track sortedBy;
  @track sortDirection = "desc";
  showSpinner = false;
  updatedisabled = true;
  @track showObj = {
    table: true,
    form: false,
    iship: false
  };
  showCompany = false;
  showMSP = false;
  contactLink;

  _shipToSource = DEFAULT_SHIP_TO_SOURCE;
  @api
  get shipToSource() {
    return this._shipToSource ?? DEFAULT_SHIP_TO_SOURCE;
  }
  set shipToSource(value) {
    this._shipToSource = value; // Store data from the parent OpportunityAddressSelector component (account, distributor, reseller)
    this._getRelatedContacts(this.shipToSource); // Automatically query Contact data based on the Ship To Source
  }

  get relatedContactsSourceString() {
    return (
      "Selected " +
      this.shipToSource?.charAt(0).toUpperCase() +
      this.shipToSource?.slice(1)
    );
  }

  get relatedContactsSourceChecked() {
    return this.shipToSource !== DEFAULT_SHIP_TO_SOURCE;
  }

  get relatedContactsSourceDisabled() {
    return (
      this.shipToSource === undefined ||
      this.shipToSource == DEFAULT_SHIP_TO_SOURCE
    );
  }

  get accountLabel() {
      if (this.objectName == 'Opportunity') {
        return 'Opportunity Account';
      } else if (this.objectName == 'Quote') {
        return 'Quote Account';
      }
  }

  selectExistingContact(event) {
    this.selectedContact = event.detail.selectedRows[0];
    this.contbtndisabled = false;
    this.selectedContactId = this.selectedContact.length
      ? [this.selectedContact.Id]
      : [];
    this.updatedisabled = false;
    this.shippingContact = this.selectedContactId;
  }

  get objectFields() {
      if (this.objectName == 'Opportunity') {
        return OPP_FIELDS;
      } else if (this.objectName == 'Quote') {
        return QUOTE_FIELDS;
      }
  }
  onHandleSort(event) {
    const { fieldName: _sortedBy, sortDirection } = event.detail;
    let sortedBy = CON_SORT_OVERRIDE[_sortedBy] ?? _sortedBy;

    const cloneData = [...this.contactResults];
    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.contactResults = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = _sortedBy;
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
      if (a == null || a === "") return 1;
      if (b == null || b === "") return -1;

      return reverse * ((a > b) - (b > a));
    };
  }

  handleOnLoad(event) {
    event.preventDefault();
  }

  handleOnChange(event) {
    this.showCompany = event.target.value;
  }

  setShowObj(table, form, iship) {
    this.selectedContact = null;
    this.showObj.table = table;
    this.showObj.form = form;
    this.showObj.iship = iship;
  }

  setShowForm() {
    this.setShowObj(false, true, false);
  }

  setShowTable() {
    this._getRelatedContacts();
    this.setShowObj(true, false, false);
  }

  handleCancel() {
    this.setShowObj(true, false, false);
  }

  // Wire the Opportunity's AccountId
  @wire(getRecord, { recordId: "$recordId", fields: "$objectFields" })
  getOppOrQuote({ error, data }) {
    this.showSpinner = true;
    if (data) {
        if (this.objectName == 'Opportunity') {
          this.accountId = data.fields.AccountId.value;
          this.shippingContact = data.fields.Shipping_Contact__c.value;
          this.accountPhone = data.fields.Account.value.fields.Phone.value;
          this.accountBillingCountry =
            data.fields.Account.value.fields.BillingCountry.value;

          this.oppRecord = {
            account: this.accountId,
            reseller: data.fields.Reseller__c.value,
            distributor: data.fields.Distributor__c.value,
            quote: data.fields.SBQQ__PrimaryQuote__c?.value
          };
        } else if ( this.objectName == 'Quote' ) {
            this.accountId = data.fields.SBQQ__Account__c.value;
            this.shippingContact = data.fields.Shipping_Contact__c.value;
            this.accountPhone = data.fields.SBQQ__Account__r.value.fields.Phone.value;
            this.accountBillingCountry =
              data.fields.SBQQ__Account__r.value.fields.BillingCountry.value;

            this.oppRecord = {
              account: this.accountId,
              reseller: data.fields.SBCF_Reseller__c.value,
              distributor: data.fields.SBQQ__Distributor__c.value
            };
        }

      if (data.fields.Business_Group__c.value === "MSP") {
        this.showMSP = true;
        this.CONTACT_COLUMNS = [...CON_COLUMNS];
      } else {
        // return every column but the one you want to hide
        this.CONTACT_COLUMNS = [...CON_COLUMNS].filter(
          (CON_COLUMNS) => CON_COLUMNS.fieldName != "MSP_End_Customer__c"
        );
      }

      if (this.shippingContact) {
        this.contactLink = "/" + this.shippingContact;
        this.setShowObj(false, false, true);
      } else {
        this.setShowTable();
      }

      this.showSpinner = false;
    } else if (error) {
      this.showSpinner = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error while searching Contact records !",
          message: error.body?.message,
          variant: "error",
          mode: "sticky"
        })
      );
    }
  }

  handleRelatedContactsAccount(event) {
    const isShipToSourceAccount = event.target.checked ?? false;
    const relatedContactsSource = isShipToSourceAccount
      ? this.shipToSource
      : DEFAULT_SHIP_TO_SOURCE;
    this._getRelatedContacts(relatedContactsSource);
  }

  _getRelatedContacts(source = this.shipToSource) {
    let shipToSourceAccountId = ((_source) => {
      if (
        typeof this.oppRecord !== "undefined" &&
        this.oppRecord !== null &&
        this.oppRecord[_source] !== null
      ) {
        return this.oppRecord[_source];
      } else {
        return this.accountId;
      }
    })(source);

    // Call the Apex method to get related Contacts
    getRelatedContacts({ accountId: shipToSourceAccountId })
      .then((result) => {
        let tempList = [];

        result.forEach((record) => {
          let rec = Object.assign({}, record);
          rec.ContactName = "/" + rec.Id;
          rec.AccountLink = "/" + rec.Account.Id;
          rec.AccountName = rec.Account.Name;

          tempList.push(rec);
        });

        this.contactResults = tempList;
        this.showSpinner = false;
      })
      .catch((error) => {
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error while searching Contact records !",
            message: error.body?.message,
            variant: "error",
            mode: "sticky"
          })
        );
      });
  }

  updateConType() {
    if (!this.selectedContact.Contact_Type__c) {
      this.selectedContact.Contact_Type__c = "Shipping";
    } else if (!this.selectedContact.Contact_Type__c.includes("Shipping")) {
      this.selectedContact.Contact_Type__c += ";Shipping";
    }
  }

  updateCon() {
    updateRecord({
      fields: {
        Id: this.selectedContact.Id,
        Contact_Type__c: this.selectedContact.Contact_Type__c
      }
    })
      .then(() => {
        this.shippingContact = this.selectedContact.Id;
        this.contactLink = "/" + this.shippingContact;
        this.updateOppOrQuote(this.selectedContact);
      })
      .catch((error) => {
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error Updating Contact",
            message: error.body?.message,
            variant: "error",
            mode: "sticky"
          })
        );
      });
  }

  createCon() {
    let mspCompany = "";
    let DoNotSyncToMarketo = false;
    let MSPEndCustomer = false;
    if (this.showCompany) {
      mspCompany = this.selectedContact.MSP_End_Customer_Company__c;
      DoNotSyncToMarketo = true;
      MSPEndCustomer = true;
    }
    const contactFields = {
      FirstName: this.selectedContact.FirstName,
      LastName: this.selectedContact.LastName,
      Email: this.selectedContact.Email,
      AccountId: this.accountId,
      LeadSource: "Unknown",
      Phone: this.accountPhone,
      Contact_Type__c: this.selectedContact.Contact_Type__c,
      Contact_Status__c: "Pending",
      MSP_End_Customer__c: MSPEndCustomer,
      MSP_End_Customer_Company__c: mspCompany,
      // DoNotSyncToMarketo__c: DoNotSyncToMarketo,
      MailingCountry: this.accountBillingCountry
    };

    const contactRecord = { apiName: "Contact", fields: contactFields };

    createRecord(contactRecord)
      .then((conRec) => {
        this.shippingContact = conRec.id;
        this.contactLink = "/" + this.shippingContact;
        this.updateOppOrQuote(conRec);
      })
      .catch((error) => {
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error creating Contact",
            message: error.body?.message,
            variant: "error",
            mode: "sticky"
          })
        );
      });
  }

  updateOppOrQuote(conRec) {
      /*
        When the Contact is selected from an existing record, the Name attribute is derived from the first and last name automatically;
        and, the Id field attribute is capitalized.
        When the Contact is created using the createRecord(), the name must be concatenated from the first and last name;
        and, the Id field attribute is lowercase.
      */
      let contactName = conRec.Name;
      if(contactName === undefined) {
        contactName = (conRec?.fields?.FirstName?.value !== undefined) ? conRec.fields.FirstName.value + ' ' : '';
        contactName += conRec?.fields?.LastName?.value;
      }

      let data = { Id: this.recordId, Shipping_Contact__c: (conRec.id ?? conRec.Id) };
      if(this.objectName == 'Quote') { Object.assign(data,{ Ship_To_Contact_Name__c : contactName }); }

      updateRecord({fields: data})
      .then(() => {
        if (
          this.oppRecord.quote !== undefined &&
          this.oppRecord.quote !== null
        ) {
          // Update Primary Quote
          updateRecord({
            fields: {
              Id: this.oppRecord.quote,
              Shipping_Contact__c: conRec.Id,
              /*SBQQ__Status__c: 'Draft',
              ApprovalStatus__c: null,*/
              Ship_To_Contact_Name__c : contactName
            }
          }).catch((error) => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: "Error updating Primary Quote",
                message: error.message,
                variant: "error",
                mode: "sticky"
              })
            );
          });
        }

        this.showSpinner = false;
        this.setShowObj(false, false, true);
      })
      .catch((error) => {
        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error Updating Opportunity",
            message: error.message,
            variant: "error",
            mode: "sticky"
          })
        );
      });
  }

  handleSave() {
    this.showSpinner = true;
    const formFields = this.template.querySelectorAll("lightning-input-field");
    const fieldVals = {};

    if (formFields) {
      formFields.forEach((field) => {
        fieldVals[field.fieldName] = field.value;
      });
    }
    this.selectedContact = fieldVals;
    this.handleFinish();
  }

  handleFinish() {
    this.showSpinner = true;
    this.updateConType();
    if (this.selectedContact.Id) {
      this.updateCon();
    } else {
      this.createCon();
    }
  }
}