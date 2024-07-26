import { LightningElement, track, wire} from 'lwc';
import { getFieldValue, getRecord  } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from "@salesforce/user/Id";
import USER_CURRENCY_CODE from "@salesforce/schema/User.Contact.Account.CurrencyIsoCode";
import USER_THEATER from "@salesforce/schema/User.Contact.Account.Terr_Theater__c";
import USER_TERRITORY from "@salesforce/schema/User.Contact.Account.Territory__c";
import USER_SUB_THEATER from "@salesforce/schema/User.Contact.Account.Terr_Sub_Theater__c";
//import getPriceListMetaData from '@salesforce/apex/PriceListHelper.getPriceListMetaData';
import getContentDocumentId from '@salesforce/apex/PriceListHelper.getContentDocumentId';
import lastUpdatedDate from '@salesforce/label/c.g_Price_List_Last_Updated_Date';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  createLibraryUserAccess from '@salesforce/apex/PriceListHelper.createLibraryUserAccess';
import  getBaseURL from '@salesforce/apex/PriceListHelper.getBaseURL';
import deleteLibraryUserAccess from '@salesforce/apex/PriceListHelper.deleteLibraryUserAccess';

export default class PriceList extends NavigationMixin(LightningElement) {

    label = {
        lastUpdatedDate
    };

    @track isTermsAndConditionAccepted = false;
    @track showDownload = false;
    @track priceListURL;
    @track progress = 0;
    @track baseURL;

    @wire(getRecord, { recordId: USER_ID, fields: [USER_CURRENCY_CODE, USER_THEATER, USER_TERRITORY, USER_SUB_THEATER] })
    user;

    get userCurrencyCode() {
        return getFieldValue(this.user.data, USER_CURRENCY_CODE);
    }

    get userTheater() {
        return getFieldValue(this.user.data, USER_THEATER);
    }

    get userTerritory() {
        return getFieldValue(this.user.data, USER_TERRITORY);
    }

    get userSubTheater() {
        return getFieldValue(this.user.data, USER_SUB_THEATER);
    }

    /*priceListData = [];
    errorData;
    @wire( getPriceListMetaData )  
    wiredRecs( value ) {
        this.wiredRecords = value;
        const { data, error } = value;
        if ( data ) {
            this.priceListData = data;
            console.log('data..'+console.log(data));
            for (var plData in data) {
                if(data[plData].Currency__c == this.userCurrencyCode && data[plData].Theater__c == this.userTheater){
                    console.log(data[plData].Currency__c+' '+data[plData].Theater__c);
                    console.log(this.userCurrencyCode+' '+this.userTheater);
                    this.priceListURL = data[plData].URL__c;
                }
            }
            this.error = undefined;
        } else if ( error ) {
            this.errorData = error;
            console.log('error..'+console.log(this.errorData));
            this.priceListData = undefined;
        }
    }*/

    /*errorData;
    @wire( getContentDocumentId, {theater: USER_THEATER,currencyCode: USER_CURRENCY_CODE})  
    wiredRecs( value ) {
        //this.wiredRecords = value;
        const { data, error } = value;
        if ( data ) {
            console.log('data...'+data);
            baseUrl = this.getBaseUrl();
            this.priceListURL = baseUrl+'sfc/servlet.shepherd/document/download/'+data;
            this.error = undefined;
        } else if ( error ) {
            this.errorData = error;
            console.log('error....'+console.log(this.errorData));
        }
    }*/    
    /*getBaseUrl(){
        let baseUrl = 'https://'+location.host+'/';
        return baseUrl;
    }*/

    getBaseUrl(){
        getBaseURL()
            .then(result => {
            console.log('getBaseURL---'+result);
            this.baseURL = result;
            })
        .catch(error => {
        this.error = error;
        console.log('Error fetching URL: ' + JSON.stringify(error) + this.baseURL);
        });       
    }

    handleTermsandConditions(event){
        if(event.target.checked){
            this.isTermsAndConditionAccepted = true;
        }else{
            this.isTermsAndConditionAccepted = false;
            this.showDownload = false;
        }
    }

    onConfirm(event){
        if(this.isTermsAndConditionAccepted){
            this.showDownload = true;
        }
    }

    wsMemberId; 
    wsPermissionId;
    isLibraryCreationSuccess;
    onDownload(event){
        console.log('USER_ID...'+USER_ID);
        createLibraryUserAccess({
            userId: USER_ID//'0053I000001Q5NbQAK'
        })
        .then(result => {
            console.log('result...'+JSON.stringify(result));
            for (let key in result) {
                if(key === 'isLibraryConfigSuccess'){
                    this.isLibraryCreationSuccess = result[key];
                }
                if(key === 'contentWSPermission'){
                    this.wsPermissionId = result[key];
                }
                if(key === 'contentWSMember'){
                    this.wsMemberId = result[key];
                }
            }
            console.log('contentWSMember...'+this.wsMemberId);
            console.log('contentWSPermission...'+this.wsPermissionId); 
            console.log('isLibraryConfigSuccess...'+this.isLibraryCreationSuccess);
            if(this.isLibraryCreationSuccess){
                this.getContenentDocument(USER_ID);
            }          
            
        })
        .catch(error => {
            this.errorData = error;
            console.log('error....'+console.log(this.errorData));
        });
        
    }

    contentDocId;
    contentDocLinkId;
    getContenentDocument(userID){
        console.log('USER_THEATER---'+this.userCurrencyCode);
        console.log('USER_CURRENCY_CODE--'+this.userTheater);
        console.log('territory--'+this.userTerritory);
        console.log('subTheater--'+this.userSubTheater);
        this.getBaseUrl();  
        getContentDocumentId({
            theater: this.userTheater,
            currencyCode: this.userCurrencyCode,
            territory: this.userTerritory,
            subTheater: this.userSubTheater,
            userId : userID
        })
        .then(result => {
            console.log('result...'+result);
            for (let key in result) {
                if(key === 'contentDocId'){
                    this.contentDocId = result[key];
                }
                if(key === 'contentDocLinkId'){
                    this.contentDocLinkId = result[key];
                }
            }                   
            if(result){
                this.priceListURL = this.baseURL+'/partners2/sfc/servlet.shepherd/document/download/'+this.contentDocId;
                console.log('priceListURL...'+this.priceListURL);
                this.error = undefined;
                this.navigateToUrl(this.priceListURL);
                

                this._interval = setInterval(() => {  
                    this.progress = this.progress + 10;
                    if ( this.progress === 10000 ) {  
                        clearInterval(this._interval);
                        console.log('interval completed...');  
                        deleteLibraryUserAccess({
                            wsMemberId: this.wsMemberId,
                            wsPermissionId: this.wsPermissionId,
                            contentDocLinkId: this.contentDocLinkId
                        })
                        .then(result => {
                            console.log('Records are deleted...');
                        })
                        .catch(error => {
                            this.errorData = error;
                            console.log('delete error....'+JSON.stringify(this.errorData));
                        });
                    }  
                }, this.progress);  

            }else{
                this.showToastErrorEvent('No Price List Found');
            }
            
        })
        .catch(error => {
            this.errorData = error;
            console.log('error....'+console.log(this.errorData));
        });
    }

    navigateToUrl(url){
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        },
        false // Opens the url in new tab
      );
    }

    showToastErrorEvent(errorMessage){
        console.log('Error Toast');
        this.spinnerVisibility = false;
        const event = new ShowToastEvent({
          title: 'Error',
          message: errorMessage,
          variant: 'error'
        });
        this.dispatchEvent(event);
      }

      previewFile(url){
        this.spinnerVisibility = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            }, false );
        
    }

}