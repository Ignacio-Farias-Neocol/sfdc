/**
 * Created by iyeung on 1/7/19.
 */

trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert, after insert,  after update) {
    new LiveChatTranscriptTriggerHandler().run();
}