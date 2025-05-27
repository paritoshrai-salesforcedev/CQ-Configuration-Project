public class CQConfigurationTriggerHandler {

    /**
     * Handles logic after inserting Case records.
     * If the current user has the 'Case_Admin' permission set and the Case type is 'Problem',
     * it creates related SQX_Nonconformance__c records and links them back to the Case.
     */
    public static void afterInsertcase(List<Case> caseRecords) {
        try {
            // Map to store Case to related Nonconformance records
            Map<Case, SQX_Nonconformance__c> caseToNcMap = new Map<Case, SQX_Nonconformance__c>();

            // Query permission assignments to ensure the current user has 'Case_Admin' permission
            List<PermissionSetAssignment> assignedPermissions = [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'Case_Admin'
            ];

            // If user has the required permission set
            if (!assignedPermissions.isEmpty()) {
                for (Case caseRecord : caseRecords) {
                    // Proceed only if Type is 'Problem' and no existing reference to Nonconformance
                    if (caseRecord.Type == 'Problem' && caseRecord.SQX_NC_Reference__c == null) {
                        // Create new Nonconformance record
                        SQX_Nonconformance__c ncRecord = new SQX_Nonconformance__c();
                        ncRecord.Priority__c = caseRecord.Priority;
                        ncRecord.Title__c = caseRecord.Subject;
                        ncRecord.Description__c = caseRecord.Description;
                        ncRecord.QMS_Reference_Number__c = caseRecord.CaseNumber;

                        // Map the case to the new Nonconformance
                        caseToNcMap.put(caseRecord, ncRecord);
                    }
                }
            }

            // If any Nonconformance records were prepared
            if (!caseToNcMap.isEmpty()) {
                // Insert Nonconformance records
                List<SQX_Nonconformance__c> ncList = caseToNcMap.values();
                Database.insert(ncList, false); // Allow partial success on insert

                // Prepare Cases to update with Nonconformance reference
                List<Case> casesToUpdate = new List<Case>();
                for (Case originalCase : caseToNcMap.keySet()) {
                    SQX_Nonconformance__c insertedNc = caseToNcMap.get(originalCase);
                    Case updateCase = new Case(
                        Id = originalCase.Id,
                        SQX_NC_Reference__c = insertedNc.Id
                    );
                    casesToUpdate.add(updateCase);
                }

                // Update Case records with reference to Nonconformance
                if (!casesToUpdate.isEmpty()) {
                    Database.update(casesToUpdate, false); // Allow partial success on update
                }
            }
        } catch (Exception e) {
            System.debug('Error in afterInsertcase: ' + e.getMessage());
        }
    }

    /**
     * Handles logic after updating Case records.
     * If a Case's Type changes to 'Problem' and the user has 'Case_Admin' permission,
     * it creates a related SQX_Nonconformance__c record and links it.
     */
    public static void afterUpdatecase(List<Case> oldCases, List<Case> newCases) {
        try {
            // Map to store Case to related Nonconformance records
            Map<Case, SQX_Nonconformance__c> caseToNcMap = new Map<Case, SQX_Nonconformance__c>();

            // Check if user has the 'Case_Admin' permission
            List<PermissionSetAssignment> assignedPermissions = [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'Case_Admin'
            ];

            // Proceed if permission exists and oldCases is not null
            if (!assignedPermissions.isEmpty() && oldCases != null) {
                for (Case oldCase : oldCases) {
                    for (Case newCase : newCases) {
                        // If the Case Type changed to 'Problem' and it's not already linked to NC
                        if (newCase.Type == 'Problem' &&
                            newCase.SQX_NC_Reference__c == null &&
                            oldCase.Type != newCase.Type) {

                            // Create a new Nonconformance record
                            SQX_Nonconformance__c ncRecord = new SQX_Nonconformance__c();
                            ncRecord.Priority__c = newCase.Priority;
                            ncRecord.Title__c = newCase.Subject;
                            ncRecord.Description__c = newCase.Description;
                            ncRecord.QMS_Reference_Number__c = newCase.CaseNumber;

                            // Map the case to the new Nonconformance
                            caseToNcMap.put(newCase, ncRecord);
                        }
                    }
                }
            }

            // If any Nonconformance records were created
            if (!caseToNcMap.isEmpty()) {
                List<SQX_Nonconformance__c> ncList = caseToNcMap.values();
                Database.insert(ncList, false); // Allow partial insert

                List<Case> casesToUpdate = new List<Case>();
                for (Case updatedCase : caseToNcMap.keySet()) {
                    SQX_Nonconformance__c insertedNc = caseToNcMap.get(updatedCase);
                    Case updateCase = new Case(
                        Id = updatedCase.Id,
                        SQX_NC_Reference__c = insertedNc.Id
                    );
                    casesToUpdate.add(updateCase);
                }

                // Update Cases with new Nonconformance reference
                if (!casesToUpdate.isEmpty()) {
                    Database.update(casesToUpdate, false);
                }
            }
        } catch (Exception e) {
            System.debug('Error in afterUpdatecase: ' + e.getMessage());
        }
    }
}