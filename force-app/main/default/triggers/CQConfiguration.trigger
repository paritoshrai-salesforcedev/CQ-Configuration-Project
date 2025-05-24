trigger CQConfiguration on Case (after insert, after update) {

    if(trigger.isInsert){
        CQConfigurationTriggerHandler.afterInsertcase(Trigger.new);
    }
    if(trigger.isUpdate){
        CQConfigurationTriggerHandler.afterUpdatecase(Trigger.old,Trigger.new);
    }
}