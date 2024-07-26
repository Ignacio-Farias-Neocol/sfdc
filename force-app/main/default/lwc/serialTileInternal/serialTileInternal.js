import { LightningElement, api } from "lwc";

export default class SerialTileInternal extends LightningElement {
  //Serial passed by the parent
  @api serial;

  //Subs passed by the parent
  @api subs;

  //Account type to determine if this is customer or partner.
  @api
  get accountType() {
    return this._accountType;
  }
  set accountType(value) {
    console.log("Account type in Serial tile: " + value);
    if (value) {
      this.partnerFieldLabel =
        value === "Customer" || value === "Internal"
          ? "Partner"
          : "Distributor";
      this._accountType = value;
    } else {
      this.partnerFieldLabel = "Partner";
    }
  }

  //Contains Account Id
  @api entityId;

  //Local Account type value
  _accountType;

  //Label for Partner/Distributor field
  partnerFieldLabel;

  //Certificate Page Name
  pageName = "SubscriptionCertificate";

  //Determines if the subscription table is visible or hidden
  subVisible = false;

  //Label for the button
  subButtonLabel = "Show Subscriptions";

  //Icon for the button
  subButtonIcon = "utility:right";

  //Handle subscription button click
  showHideSubscription() {
    if (!this.subVisible) {
      //Show Table
      this.subVisible = true;
      this.subButtonLabel = "Hide Subscriptions";
      this.subButtonIcon = "utility:down";
    } else {
      //Hide Table
      this.subVisible = false;
      this.subButtonLabel = "Show Subscriptions";
      this.subButtonIcon = "utility:right";
    }
  }
}