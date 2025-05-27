@isTest
public class CQConfigurationTriggerHandlerTest {

    /**
     * Utility method to create a user with a specific profile
     * and optionally assign the existing 'Case_Admin' permission set.
     */
    private static User createUser(String profileName, Boolean assignPermissionSet) {
        // Query the profile by name
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        // Create a new user with the specified profile
        User u = new User(
            Username = profileName.replace(' ', '').toLowerCase() + DateTime.now().getTime() + '@example.com',
            Alias = 'usr',
            Email = 'user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;

        // Assign the 'Case_Admin' permission set if requested
        if (assignPermissionSet) {
            List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Admin' LIMIT 1];
            if (!psList.isEmpty()) {
                insert new PermissionSetAssignment(
                    AssigneeId = u.Id,
                    PermissionSetId = psList[0].Id
                );
            }
        }

        return u;
    }

    // ----------------- ADMIN USER TESTS -----------------

    /**
     * Test for inserting a Case with Type = 'Problem' by a System Admin with Case_Admin permission.
     * This should create a SQX_Nonconformance__c record and set the reference on the Case.
     */
    @isTest static void test_AdminUser_Positive_Insert() {
        User admin = createUser('System Administrator', true);
        System.runAs(admin) {
            Case c = new Case(Subject = 'Admin Insert', Type = 'Problem', Priority = 'High', Description = 'Admin insert');
            Test.startTest(); 
                insert c; 
            Test.stopTest();

            // Assert that the Case now has a non-null reference to a Nonconformance record
            System.assertNotEquals(null, [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id].SQX_NC_Reference__c);
        }
    }

    /**
     * Test for inserting a Case with Type != 'Problem' by an Admin.
     * No Nonconformance record should be created.
     */
    @isTest static void test_AdminUser_Negative_Insert_TypeNotProblem() {
        User admin = createUser('System Administrator', true);
        System.runAs(admin) {
            Case c = new Case(Subject = 'Admin Insert Fail', Type = 'Request', Priority = 'Low', Description = 'Wrong type');
            Test.startTest(); 
                insert c; 
            Test.stopTest();

            System.assertEquals(0, [SELECT COUNT() FROM SQX_Nonconformance__c WHERE QMS_Reference_Number__c = :c.CaseNumber]);
            System.assertEquals(null, [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id].SQX_NC_Reference__c);
        }
    }

    /**
     * Test for updating a Case where the Type changes to 'Problem'.
     * A Nonconformance should be created if the user has permission.
     */
    @isTest static void test_AdminUser_Positive_Update_TypeChangedToProblem() {
        User admin = createUser('System Administrator', true);
        System.runAs(admin) {
            Case c = new Case(Subject = 'Admin Update', Type = 'Request', Priority = 'Medium', Description = 'Initial');
            insert c;

            c.Type = 'Problem';
            Test.startTest(); 
                update c; 
            Test.stopTest();

            System.assertNotEquals(null, [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id].SQX_NC_Reference__c);
        }
    }

    /**
     * Test for updating a Case without changing the Type.
     * Should not create a new Nonconformance record.
     */
    @isTest static void test_AdminUser_Negative_Update_TypeUnchanged() {
        User admin = createUser('System Administrator', true);
        System.runAs(admin) {
            Case c = new Case(Subject = 'Admin No Change', Type = 'Problem', Priority = 'High', Description = 'Original');
            insert c;

            c.Priority = 'Low'; // Only change priority, not type
            Test.startTest(); 
                update c; 
            Test.stopTest();

            System.assertNotEquals(null, [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id].SQX_NC_Reference__c);
        }
    }

    // ----------------- NON-ADMIN USER TESTS -----------------

    /**
     * Test for non-admin user inserting a Case of type 'Problem'.
     * Since the user lacks the required permission, nothing should happen.
     */
    @isTest static void test_NonAdminUser_Negative_Insert_TypeIsProblem() {
        User nonAdmin = createUser('Standard User', false);
        System.runAs(nonAdmin) {
            Case c = new Case(Subject = 'NonAdmin Insert', Type = 'Problem', Priority = 'High', Description = 'No perms');
            Test.startTest(); 
                insert c; 
            Test.stopTest();

            System.assertEquals(0, [SELECT COUNT() FROM SQX_Nonconformance__c WHERE QMS_Reference_Number__c = :c.CaseNumber]);
            System.assertEquals(null, [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id].SQX_NC_Reference__c);
        }
    }

    /**
     * Test for non-admin user inserting a Case of a type other than 'Problem'.
     * Expected: No Nonconformance creation as it doesn't meet the condition.
     */
    @isTest static void test_NonAdminUser_Negative_Insert_TypeNotProblem() {
        User nonAdmin = createUser('Standard User', false);
        System.runAs(nonAdmin) {
            Case c = new Case(Subject = 'NonAdmin No Trigger', Type = 'Request', Priority = 'Low', Description = 'Not problem');
            Test.startTest(); 
                insert c; 
            Test.stopTest();

            System.assertEquals(0, [SELECT COUNT() FROM SQX_Nonconformance__c WHERE QMS_Reference_Number__c = :c.CaseNumber]);
        }
    }

    /**
     * Test for non-admin user updating a Case where the Type is changed to 'Problem'.
     * Since user lacks permission, no Nonconformance should be created.
     */
    @isTest static void test_NonAdminUser_Negative_Update_TypeChangedToProblem() {
        User nonAdmin = createUser('Standard User', false);
        System.runAs(nonAdmin) {
            Case c = new Case(Subject = 'NonAdmin Update', Type = 'Request', Priority = 'Medium', Description = 'Initial');
            insert c;

            c.Type = 'Problem';
            Test.startTest(); 
                update c; 
            Test.stopTest();

            System.assertEquals(0, [SELECT COUNT() FROM SQX_Nonconformance__c WHERE QMS_Reference_Number__c = :c.CaseNumber]);
            System.assertEquals(null, [SELECT SQX_NC_Reference__c FROM Case WHERE Id = :c.Id].SQX_NC_Reference__c);
        }
    }

    /**
     * Test for non-admin user updating a Case without changing the Type.
     * No Nonconformance should be created.
     */
    @isTest static void test_NonAdminUser_Negative_Update_TypeUnchanged() {
        User nonAdmin = createUser('Standard User', false);
        System.runAs(nonAdmin) {
            Case c = new Case(Subject = 'NonAdmin No Change', Type = 'Problem', Priority = 'High', Description = 'Initial');
            Test.startTest(); 
                insert c;

            c.Priority = 'Medium'; // Only priority is changed
            update c; 
            Test.stopTest();

            System.assertEquals(0, [SELECT COUNT() FROM SQX_Nonconformance__c WHERE QMS_Reference_Number__c = :c.CaseNumber]);
        }
    }
}