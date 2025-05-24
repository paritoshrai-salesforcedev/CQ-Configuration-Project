public class CQConfigurationTriggerHandler {
	
    public static void afterInsertcase(List<Case> caseRecord){
        Map<Case,SQX_Nonconformance__c> SQX= new map<case,SQX_Nonconformance__c>();
        List<PermissionSetAssignment> premAssigned=[Select id from PermissionSetAssignment where AssigneeId=:UserInfo.getUserId() and PermissionSetId='0PSNS00000AcpF3'];
        if(!premAssigned.isEmpty()){
            for(Case SQXcase: caseRecord){
                if(SQXcase.Type=='Problem' && SQXcase.SQX_NC_Reference__c==null){
                    SQX_Nonconformance__c SQXNCF= new SQX_Nonconformance__c();
                    SQXNCF.Priority__c=SQXcase.Priority;
                    SQXNCF.Title__c=SQXcase.Subject;
                    SQXNCF.Description__c=SQXcase.Description;
                    SQXNCF.QMS_Reference_Number__c=SQXcase.CaseNumber;
                    
                    SQX.put(SQXcase,SQXNCF);
                }
            }
            }
        if(SQX!=Null){
            List<SQX_Nonconformance__c> SQXcaseNCF=SQX.values();
            Database.Insert(SQXcaseNCF);
            List<Case> SQXcase= new List<Case>();
            for(case SQXcaseNCFRecord: SQX.KeySet()){
                SQX_Nonconformance__c SQXNFCRecord=[Select Id from SQX_Nonconformance__c where QMS_Reference_Number__c=:SQXcaseNCFRecord.CaseNumber ];
                Case caseToUpdate = new Case(
                Id = SQXcaseNCFRecord.Id,
                SQX_NC_Reference__c = SQXNFCRecord.Id
            );
                SQXcase.add(caseToUpdate);
            }
            if(SQXcase!=Null){
                Database.Update(SQXcase);
            }
            
        }
    }
    
    public static void afterUpdatecase(List<case> oldCase, List<Case> newCase){
        Map<Case,SQX_Nonconformance__c> SQX= new map<case,SQX_Nonconformance__c>();
        List<PermissionSetAssignment> premAssigned=[Select id from PermissionSetAssignment where AssigneeId=:UserInfo.getUserId() and PermissionSetId='0PSNS00000AcpF3'];
        if(!premAssigned.isEmpty()){
            for(Case SQXoldCase: oldCase){
            for(Case SQXcase: newCase){
                if(SQXcase.Type=='Problem' && SQXcase.SQX_NC_Reference__c==null && (SQXoldCase.Type!=SQXcase.Type)){
                    SQX_Nonconformance__c SQXNCF= new SQX_Nonconformance__c();
                    SQXNCF.Priority__c=SQXcase.Priority;
                    SQXNCF.Title__c=SQXcase.Subject;
                    SQXNCF.Description__c=SQXcase.Description;
                    SQXNCF.QMS_Reference_Number__c=SQXcase.CaseNumber;
      
                    SQX.put(SQXcase,SQXNCF);
                }
            }
            }
            }
        if(SQX!=Null){
           List<SQX_Nonconformance__c> SQXcaseNCF=SQX.values();
            Database.Insert(SQXcaseNCF);
            List<Case> SQXcase= new List<Case>();
            for(case SQXcaseNCFRecord: SQX.KeySet()){
                SQX_Nonconformance__c SQXNFCRecord=[Select Id from SQX_Nonconformance__c where QMS_Reference_Number__c=:SQXcaseNCFRecord.CaseNumber ];
                Case caseToUpdate = new Case(
                Id = SQXcaseNCFRecord.Id,
                SQX_NC_Reference__c = SQXNFCRecord.Id
            );
                SQXcase.add(caseToUpdate);
            }
            if(SQXcase!=Null){
                Database.Update(SQXcase);
            }
            
        }
    }
}