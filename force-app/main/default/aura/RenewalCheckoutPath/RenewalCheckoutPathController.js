({
    init: function(component, event, helper) {
      var progressIndicator = component.find("progressIndicator");
      setTimeout(() =>{
          var currentStep = component.get("v.currentStage");
          var stageData = [];
          for (let step of component.get("v.stages")) {
          stageData.push([
              'lightning:progressStep',
              {
                  "aura:id": "step_" + step,
                  label: step,
                  value: step
              }]
          );
          }
  
          $A.createComponents(
              stageData,
              function(stages) {
                  $A.createComponents(
                      [['lightning:progressIndicator', { 
                          currentStep: currentStep, 
                          body: stages,
                          type: 'path'
                      }]],
                      function(indicator) {
                          component.set("v.body", indicator);
                      }
                  )
              }
          );
      }, 1);
    }
  });