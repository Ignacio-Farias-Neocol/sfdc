import { LightningElement, api } from 'lwc';

export default class SerialTileMsp extends LightningElement {

  localSerial;

  //Serials provided by parent
  @api 
  get serial(){
    return this.localSerial;
  }
  set serial(value){
    this.localSerial = value;
    console.log('Tile Serial: ' + JSON.stringify(value));
  }
}