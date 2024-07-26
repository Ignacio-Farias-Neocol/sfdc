import { LightningElement, api } from 'lwc';

export default class EmptyStateIllustration extends LightningElement {

  //Message to be displayed on the screen
  @api message;

  //Class value
  classValue;

  //Illustration size
  @api illustrationSize
}