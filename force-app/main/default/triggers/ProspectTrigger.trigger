trigger ProspectTrigger on Prospect__c (after update) {
    
    if(Trigger.isAfter && Trigger.isUpdate){
        ProspectTriggerHandler.handleActivitiesAfterUpdate(Trigger.New);
    }

}