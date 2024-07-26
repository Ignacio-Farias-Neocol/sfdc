import { LightningElement,api,wire} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import SplashBackground from '@salesforce/resourceUrl/SplashBackground';
import initData from "@salesforce/apex/SplashPageController.initData";
import dismissSplash from "@salesforce/apex/SplashPageController.dismissSplash";
import Security_Notice_Contact_Set_Up_URL from '@salesforce/label/c.Security_Notice_Contact_Set_Up_URL';



export default class SplashPage extends LightningElement {

    @api recordId;
    showPopup = false;
    currentPageReference = null; 
    urlStateParameters = null;
    label = {
        Security_Notice_Contact_Set_Up_URL
    };

    SplashBackgroundImg = SplashBackground;
    isInit = false;
    finalShowPopup = false;

    get bgImageStyle() {
        return `background: transparent url(${SplashBackground}) 0% 0% no-repeat padding-box;
        opacity: 1;min-height: 65vh;`;
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
          console.log(currentPageReference);
          this.recordId = currentPageReference.attributes.recordId || null;

          this.showPopup = false; 
          let currentPageURL = location.href;
          if(currentPageURL.indexOf('contact/Contact') != -1){
          }else if(this.recordId != undefined && this.recordId.startsWith('003')){
          }else if(this.recordId != undefined && this.recordId.startsWith('001')){
          }else{
              this.showPopup = true;
          }
       }
    }

    connectedCallback(){
        let currentPageURL = location.href;
        if(currentPageURL.indexOf('contact/Contact') != -1){
        }else if(this.recordId != undefined && this.recordId.startsWith('003')){
        }else if(this.recordId != undefined && this.recordId.startsWith('001')){
        }else{
            this.showPopup = true;
        }
        if(this.isInit){
            return;
        }
        this.isInit = true;
        this.initDataJS();
    }
    closePopup(){
        this.finalShowPopup = false;
    }

    initDataJS(){
        debugger;
        initData()
        .then(result =>{
           // let jsonRes = JSON.parse(result);
            let jsonRes = result;
            if(jsonRes.isShowSplash){
                this.finalShowPopup = true;
            }
        })
        .catch(result => {
            console.log(result);
        }); 
    }

    handleDismiss(){
        dismissSplash()
        .then(result =>{
            //let jsonRes = JSON.parse(result);
            this.finalShowPopup = false;
        })
        .catch(result => {
            console.log(result);
        }); 
    }
}