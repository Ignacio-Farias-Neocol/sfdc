/**
 * Created by: Salesforce Services
 * Created date: 03/25/2020
 * Description: ES6 module containing functions that can be used across different components 
 */

 //Function to sort array of objects based on string property
const stringSort = (data, propertyName, direction) => {
  data.sort(function(a, b){
    var x = a[propertyName]? a[propertyName].toLowerCase(): a[propertyName];
    var y = b[propertyName]? b[propertyName].toLowerCase(): b[propertyName];
    if (x < y) {return direction.toUpperCase() ==='ASC'?-1:1;}
    if (x > y) {return direction.toUpperCase() ==='ASC'?1:-1;}
    return 0;
  });
};

 //Function to sort array of objects based on string property
 const numberSort = (data, propertyName, direction) => {
  data.sort(function(a, b){
    if(direction.toUpperCase() ==='ASC'){
      return a[propertyName] - b[propertyName];
    }
    else{
      return b[propertyName] - a[propertyName];
    }
  });
};

 //Function to sort array of objects based on string property
 const dateSort = (data, propertyName, direction) => {
  data.sort(function(a, b){
    const x = new Date(a[propertyName]);
    const y = new Date(b[propertyName]);
    if(direction.toUpperCase() ==='ASC'){
      return x - y;
    }
    else{
      return y - x;
    }
  });
};

export { stringSort, numberSort, dateSort };