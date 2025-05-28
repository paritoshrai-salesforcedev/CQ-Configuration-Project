// Trigger on Case object that executes after insert and after update operations
trigger CQConfiguration on Case (after insert, after update) {

    // If the operation is an insert
    if(trigger.isInsert && trigger.isAfter){
        // Call the handler method to process logic for new Case records
        CQConfigurationTriggerHandler.afterInsertcase(Trigger.new);
    }

    // If the operation is an update
    if(trigger.isUpdate && trigger.isAfter){
        // Call the handler method to process logic for updated Case records
        // Pass both old and new Case lists to detect changes
        CQConfigurationTriggerHandler.afterUpdatecase(Trigger.old, Trigger.new);
    }
}