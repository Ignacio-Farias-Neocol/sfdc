({
    // notification helper method
    notificationHelper : function(component, variant, title, errMsg) {
        component.find('notifLib').showToast({
            "variant": variant,
            "title": title,
            "message": errMsg
        });  	
    }, 
})