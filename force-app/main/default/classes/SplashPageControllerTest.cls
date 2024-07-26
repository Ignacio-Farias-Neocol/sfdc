@isTest
class SplashPageControllerTest {
    
    @isTest
    static void testSplashPageController() {
        SplashPageController.initData();
        SplashPageController.dismissSplash();
        SplashPageController.initData();
    }
}