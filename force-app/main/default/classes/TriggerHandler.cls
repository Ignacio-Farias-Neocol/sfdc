/**
*   @description   Trigger Handler based upon github.com/kevinohara80/sfdc-trigger-framework
*
*
*    @author Ivan Yeung
*    @date 01/11/2016
*    @group Trigger
*/
public virtual class TriggerHandler {

    // static map of handlername, times run() was invoked
    private static final Map<String, LoopCount> loopCountMap = new Map<String, LoopCount>();
    private static final Set<String> bypassedHandlers = new Set<String>();
    private static Set<TriggerHandler> preAutoHandlers = new Set<TriggerHandler>();
    private static Set<TriggerHandler> postAutoHandlers = new Set<TriggerHandler>();

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        
        for (Trigger_Handler__mdt meta : [
            select
                TriggerHandler_Class__c,
                Trigger_Order__c
            from Trigger_Handler__mdt
            where Is_Active__c = true
        ]) {

            Type t = Type.forName(meta.TriggerHandler_Class__c);
            if (t != null) {
                Object obj = t.newInstance();
                if (obj instanceof TriggerHandler) {

                    TriggerHandler handler = (TriggerHandler)obj;
                    if (meta.Trigger_Order__c == 'PRE') {
                        preAutoHandlers.add(handler);
                    }
                    else if (meta.Trigger_Order__c == 'POST') {
                        postAutoHandlers.add(handler);
                    }
                    
                }
            }
            
        }

    }

    // constructor
    public TriggerHandler() {
        this.setTriggerContext();
    }

  /***************************************
   * public instance methods
   ***************************************/

    // main method that will be called during execution
    public void run() {

        if(!validateRun(this)) return;

        addToLoopCount();

        // run pre-step handlers
        runHandlers(preAutoHandlers, this);
        // dispatch to the correct handler method
        runInstance(this);
        // run post-step handlers
        runHandlers(postAutoHandlers, this);

    }

    private static void runHandlers(Set<TriggerHandler> handlers, TriggerHandler parent) {

        for (TriggerHandler handler : handlers) {
            // assume context of "parent" handler
            handler.context = parent.context;
            handler.isTriggerExecuting = parent.isTriggerExecuting;

            if (validateRun(handler)) {

                runInstance(handler);

            }

        }

    }

    private static void runInstance(TriggerHandler handler) {

        //try {

            if(handler.context == TriggerContext.BEFORE_INSERT) {
                handler.beforeInsert();
            } else if(handler.context == TriggerContext.BEFORE_UPDATE) {
                handler.beforeUpdate();
            } else if(handler.context == TriggerContext.BEFORE_DELETE) {
                handler.beforeDelete();
            } else if(handler.context == TriggerContext.AFTER_INSERT) {
                handler.afterInsert();
            } else if(handler.context == TriggerContext.AFTER_UPDATE) {
                handler.afterUpdate();
            } else if(handler.context == TriggerContext.AFTER_DELETE) {
                handler.afterDelete();
            } else if(handler.context == TriggerContext.AFTER_UNDELETE) {
                handler.afterUndelete();
            }

        //}
        //catch (Exception e) {
        //    LogModel.startLog(getHandlerName(handler), handler.context.name()).addExceptionLog(e);
        //}

    }

    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName(this);
        if(!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

  /***************************************
   * public static methods
   ***************************************/

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
    }

  /***************************************
   * private instancemethods
   ***************************************/

    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
                (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
                (ctx != null && ctx == 'before update')){
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
                (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
                (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
                (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
                (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
                (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName(this);
        if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
            if(exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }

    // make sure this trigger should continue to run
    @TestVisible
    private static Boolean validateRun(TriggerHandler handler) {
        if(!handler.isTriggerExecuting || handler.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName(handler))) {
            return false;
        }
        return true;
    }

    @TestVisible
    private static String getHandlerName(TriggerHandler handler) {
        return String.valueOf(handler).substring(0,String.valueOf(handler).indexOf(':'));
    }

  /***************************************
   * context methods
   ***************************************/

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}

  /***************************************
   * inner classes
   ***************************************/

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if(this.max < 0) return false;
            if(this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }

    // exception class
    public class TriggerHandlerException extends Exception {}

}