import { LightningElement, api, wire, track } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';

//Import custom labels
import renewSubscriptionButtonLabel from '@salesforce/label/c.g_SerialTile_RenewSubscriptionButton_Label';
import requestModificationButtonLabel from '@salesforce/label/c.g_SerialTile_RequestModificationButton_Label';
import viewSubscriptionCertificate from '@salesforce/label/c.g_SerialTile_ViewSubscriptionCertificate_Label';
import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';

export default class SerialTile extends LightningElement {

  @api isReadOnly = false;

  //Serial passed by the parent
  @api 
  get serial(){
    return this._serial;
  }

  set serial(value){
    this._serial = value;
  }

  //Account type to determine if this is customer or partner. 
  @api
  get accountType() {
    return this._accountType;
  }
  set accountType(value) {
    console.log("Account type in Serial tile: " + value);
    if(value){
      this.partnerFieldLabel = value === 'Customer' || value === 'Internal' ? 'Partner' : 'Distributor';
      this._accountType = value;
    }
    else{
      this.partnerFieldLabel = 'Partner';
    }
  }

  @api
  disableRenewal() {
    this.renewalDisabled = true;
  }

  connectedCallback() {
    let allEOL = true;
    //Performs 2 checks.
    //1. If any subscription is EOL
    //2. If all subscriptions are EOL
    //If 1 has been changed to true and 2 has been changed to false, can terminate the loop early
    for(let i=0; i< this.serial.subs.length; i++) {
      if(this.serial.subs[i].lifeCycleStatus === 3) {
        this.hasEOL = true;
      }
      else {
        allEOL = false;
        if(this.hasEOL) {
          break;
        }
      }
    }
    if(allEOL){
      this.renewalDisabled = true;
      this.renewalDisabledText += 'Disabled because all products are EOL.\n';
    }
    if(this.serial.hasOpenCase) {
      this.renewalDisabled = true;
      this.renewalDisabledText += 'Disabled because serial has an open Case.\n';
    }
    if(!this.serial.hasRenewalOpp) {
      this.renewalDisabled = true;
      this.renewalDisabledText += 'Disabled because serial does not have Renewal Opp.\n';
    }
    if(!this.serial.isBillToAccount) {
      this.renewalDisabled = true;
      this.renewalDisabledText += 'Disabled because account is not the bill to account.\n';
    }
    if(!this.serial.isQuoteApproved) {
      this.renewalDisabled = true;
      this.renewalDisabledText += 'Disabled because primary quote has not been approved.\n';
    }
    // console.log('Determining if modification should be enabled');
    // if(this.serial.partner && this.accountType == 'Customer'){
    //   this.modificationDisabled = true;
    // } else if(!this.serial.isBillToAccount) {
    //   this.modificationDisabled = true;
    // } else {
    //   this.modificationDisabled = false;
    // }
  }

  label = {
    renewSubscriptionButtonLabel,
    requestModificationButtonLabel,
    viewSubscriptionCertificate
  }

  //Local Account type value
  _accountType;

  //Local serial vaue
  _serial;

  //Determines if the "Modification Request" button is disabled
  modificationDisabled = false;

  //Determines if the "Renewal Subscription" button is disabled
  renewalDisabled = false;
  renewalDisabledText = '';

  //Determines if there are EoL products for the serial
  hasEOL = false;

  //Label for Partner/Distributor field
  partnerFieldLabel;

  //Certificate Page Name
  pageName = "SubscriptionCertificate";

  //Changes card border based on selection
  get boxCSSClass() {
    return "slds-box slds-box_xx-small";
  }

  //Card Title
  get cardTitle() {
    return "Subscriptions for Serial # " + this.serial.serialNumber;
  }

  //Event fired when 'Request Modification' button is selected
  showModificationRequestModal(event) {
    this.bubbleEvent(event, 'showmodificationrequest', {
      detail: {
        opportunityId: this.serial.renewalOppId,
        accountId: this.serial.accountId,
        accountName: this.serial.accountName,
        quoteName : this.serial.quoteName
      }
    });
  }
  //Event fired when a'Renew Subscription' button is selected
  navigateToSubscriptionRenewal(event) {
    this.bubbleEvent(event, 'renewserial', {
      detail: {
        requiresConfirmation: this.hasEOL,
        quoteId: this.serial.quoteId,
        serialId: this.serial.id
      }
    });
  }

  //Event fired when a serial is selected
  serialSelected(event) {
    this.bubbleEvent(event, 'serialselection', {
      detail: this.serial.id
    });
  }

  //Generic event distacher
  bubbleEvent(event, eventName, prop) {
    console.log(`Firing event ${eventName}`);
    // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
    event.preventDefault();

    // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
    const selectedEvent = new CustomEvent(eventName, prop);

    // 3. Fire the custom event
    // console.log("Serial Selected: " + this.serial.id);
    this.dispatchEvent(selectedEvent);
  }
// Aditya Changes to Hide the Renew Subscription Button For Customer Community 
  profileName;
  error;
  @track hideRenewSubscription = false;
  @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME_FIELD]}) 
  userDetails({error, data}) {
      if (data) {
          this.profileName = data.fields.Profile.value.fields.Name.value; ;
          console.log('profileName...'+this.profileName);
          if(this.profileName == 'Apollo: MFA Barracuda CCPlus Admin Login Profile' || 
              this.profileName == 'Customer Community Plus Login User' ||
              this.profileName == 'Apollo: Barracuda CCPlus Admin Login Profile' || 
              this.profileName == 'Apollo: Barracuda CCPlus Login Profile'
            ){
              this.hideRenewSubscription = true;
          }
      } else if (error) {
          this.error = error ;
      }
  }

}