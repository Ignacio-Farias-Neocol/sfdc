@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void testLoginWithInvalidCredentials() {
  System.assertEquals('url cannot be null', LightningLoginFormController.login('testUser', 'fakepwd', null));
 }

 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertNotEquals(null, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
 }
    
 @IsTest
 static void testPartnerNetwork() {
  Boolean isPartnerPortal = LightningLoginFormController.getNetworkName();
 }
    
 @IsTest
 static void testForgotPassword() {
  String authConfig = LightningLoginFormController.getForgotPasswordUrl();
  System.assertNotEquals('null', authConfig);
 }
    
 @IsTest
 static void testSetExperienceId() {
  String authConfig = LightningLoginFormController.setExperienceId('ABC123456');
  //System.assertNotEquals('null', authConfig);
 } 
}