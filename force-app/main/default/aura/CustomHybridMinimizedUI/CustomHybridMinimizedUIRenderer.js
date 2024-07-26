({
    afterRender : function(cmp, helper){
        this.superAfterRender();
        var elements = document.getElementsByClassName("offlineSupportUI");
        console.log('displaying the elements retrieved');
        console.log("elements.length: " + elements.length);
        for (var i=0; i<elements.length; i++) {
            console.log(elements[i].innerHTML);
            elements[i].innerHTML = $A.get("$Label.c.Live_Chat_Offline_Message");
            document.getElementsByTagName('embeddedservice-chat-header')[0].getElementsByTagName('header')[0].getElementsByTagName('h2')[0].innerHTML = 'No Agents Are Available';  
        }
        
    }
})