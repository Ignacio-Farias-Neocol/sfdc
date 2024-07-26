import { LightningElement, api, wire } from 'lwc';
export default class SearchBeforeCreate_Page extends LightningElement {
    @api 
    pageName = null;
    
    @api 
    currentPage = null;

    @api
    resultsPageHeader='';
    

    get isCurrentPage() {
        return (this.pageName === this.currentPage);
    }
}