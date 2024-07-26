import { LightningElement, api, track } from 'lwc';
export default class SearchBeforeCreate_Base extends LightningElement {
    showContainer = true;
    @api recordId;
    @api titleString = 'Search Before Create';
    @api superTitleString = null;
    @api showSpinner = false;

}