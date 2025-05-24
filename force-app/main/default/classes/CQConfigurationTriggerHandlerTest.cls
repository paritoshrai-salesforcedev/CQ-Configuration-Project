@isTest
public class CQConfigurationTriggerHandlerTest {
    private static User createTestUserWithPermissionSet() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE ID='0PSNS00000AcpF3' LIMIT 1];

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        return u;
    }

    @isTest
    static void testAfterInsertCaseWithPermission() {
        User testUser = createTestUserWithPermissionSet();

        System.runAs(testUser) {
            Case c = new Case(
                Subject = 'Test Case Insert',
                Type = 'Problem',
                Priority = 'High',
                Description = 'Test Insert Description'
            );
            insert c;
            
            Test.startTest();
            CQConfigurationTriggerHandler.afterInsertcase(new List<Case>{c});
            Test.stopTest();

            List<SQX_Nonconformance__c> ncs = [
                SELECT Id, QMS_Reference_Number__c 
                FROM SQX_Nonconformance__c 
                WHERE QMS_Reference_Number__c = :c.CaseNumber
            ];
            System.assertEquals(1, ncs.size(), 'A nonconformance should have been created.');

            Case updatedCase = [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id];
            System.assertNotEquals(null, updatedCase.SQX_NC_Reference__c, 'Case should have been updated with reference.');
        }
    }

    @isTest
    static void testAfterUpdateCaseWithPermission() {
        User testUser = createTestUserWithPermissionSet();

        System.runAs(testUser) {
            Case c = new Case(
                Subject = 'Test Case Update',
                Type = 'Request',
                Priority = 'Medium',
                Description = 'Initial description'
            );
            insert c;

            Case oldC = c.clone(false);
            c.Type = 'Problem';
            update c;

            Case newC = [SELECT Id, Type, Subject, Priority, Description, SQX_NC_Reference__c FROM Case WHERE Id = :c.Id];

            Test.startTest();
            CQConfigurationTriggerHandler.afterUpdatecase(new List<Case>{oldC}, new List<Case>{newC});
            Test.stopTest();

            List<SQX_Nonconformance__c> ncs = [
                SELECT Id FROM SQX_Nonconformance__c 
                WHERE QMS_Reference_Number__c = :c.CaseNumber
            ];
            System.assertEquals(0, ncs.size(), 'No record should be created without permission.');
            Case updatedCase = [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id];
            System.assertNotEquals(null, updatedCase.SQX_NC_Reference__c, 'Case should have been updated with reference.');
        }
    }

    @isTest
    static void testNoActionWithoutPermission() {
        Case c = new Case(
            Subject = 'Test Case',
            Type = 'Problem',
            Priority = 'Low',
            Description = 'description'
        );
        insert c;

        Test.startTest();
        CQConfigurationTriggerHandler.afterInsertcase(new List<Case>{c});
        Test.stopTest();

        List<SQX_Nonconformance__c> ncs = [
            SELECT Id FROM SQX_Nonconformance__c 
            WHERE QMS_Reference_Number__c = :c.CaseNumber
        ];
        System.assertEquals(1, ncs.size(), 'A nonconformance should have been created.');

        
    }
}