// https://rajvakati.com/2018/12/28/platform-events-subscribe-using-lightning-component/
({
    // Sets an empApi error handler on component initialization
    onInit : function(component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');
        //  below line to enable debug logging (optional)
        empApi.setDebugFlag(true);
    },
    // Invokes the subscribe method on the empApi component
    subscribe : function(component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the channel from the input box
        const channel = component.find('channel').get('v.value');
        // Replay option to get new events
        const replayId = -1;

        // Subscribe to an event
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            // Process event (this is called each time we receive an event)
            component.set('v.results', JSON.stringify(eventReceived.data.payload));
        console.log('Received event 1 ', eventReceived.data);

        console.log('Received event2  ', eventReceived.data.payload);
    }))
    .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            console.log('Subscribed to channel ', subscription.channel);
        // Save subscription to unsubscribe later
        component.set('v.subscription', subscription);
    });
    },

    // Invokes the unsubscribe method on the empApi component
    unsubscribe : function(component, event, helper) {
        // Get the empApi component
        const empApi = component.find('empApi');
        // Get the subscription that we saved when subscribing
        const subscription = component.get('v.subscription');

        // Unsubscribe from event
        empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
            // Confirm that we have unsubscribed from the event channel
            console.log('Unsubscribed from channel '+ unsubscribed.subscription);
        component.set('v.subscription', null);
    }));
    }
})