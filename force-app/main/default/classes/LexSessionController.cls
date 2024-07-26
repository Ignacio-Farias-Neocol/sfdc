public class LexSessionController {
    
    public static String fetchUserSessionId(){
        String sessionId = '';
        // Refer to the Page
        
       
        PageReference sessionIdPage = Page.LexGetSessionIdPage;
        
        // Get the content of the VF page
        String vfContent;
        if(!Test.isRunningTest()){
            vfContent = sessionIdPage.getContent().toString();
        }else{
            vfContent = 'StartTestsesEndsion'; 
        }
        
        // Find the position of Start and End
        Integer startPosition = vfContent.indexOf('Start') + 'Start'.length(),
            endPosition = vfContent.indexOf('End');
        // Get the Session Id
        sessionId = vfContent.substring(startPosition, endPosition);
        
        System.debug('sessionId '+sessionId);
        // Return Session Id
        return sessionId;
    
    }
}