import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
/** getSubscriptions() method in ProductListViewHelper Apex class */
import getUrl from "@salesforce/apex/ProductListViewHelper.getUrlcert";


export default class CertificateButton extends NavigationMixin(LightningElement) {
    
  //publicly avaiable attributes
  @api btnIconName;
  @api btnIconAltText;
  @api btnIconTitle;
  @api serial;
  @api pageName;
  @api serialId;
  @api entityId;
  localAccountType;

  @api 
  get accountType(){
    return this.localAccountType;
  }
  set accountType(value){
    if(value!=undefined){
      this.localAccountType = value;
      this.showButton = value === "Internal" ? true : false; 
      console.log('Account Type: ' + value);
      console.log('Show Button Value: ' + this.showButton);
    } 
    else{
      this.showButton = false;
      console.log('Account Type: ' + value);
      console.log('Show Button Value: ' + this.showButton);
    } 
  }

  showButton;

  _pageURL;

  viewCertificate(){
    console.log('Show Certificate') ;
    console.log('serialId--'+ this.serial.id) ;
    getUrl({pageName: "SubscriptionCertificate", serialId: this.serial.id})
            .then(result => {
              console.log(result);
              //SFDC-14547: Removing ProductName and Account Id because these fields are on Serial now and can be fetched from the record.
              this._pageURL = result + 
                              '?id=' + this.serial.id + 
                              // '&productName=' + (this.serial.productName ? this.serial.productName : "")
                              '&partner='+ (this.serial.partner ? this.serial.partner : "") + 
                              '&accountType=' + (this.localAccountType ? this.localAccountType : "");
                              // '&aId=' + (this.entityId ? this.entityId : "");
              window.open(this._pageURL, "_blank");
            })
            .catch(error => {
              this.error = error;
              console.log('Error fetching URL: ' + JSON.stringify(error) + this._pageURL);
            });
  }
}