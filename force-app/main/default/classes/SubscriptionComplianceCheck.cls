global class SubscriptionComplianceCheck implements Database.Batchable<sObject> {
    private static final String ELEMENTS_MANQUANTS = 'Éléments manquants';
    private static final String IMMO_NEUF = 'Conformité Immo neuf';
    private static final String CONFORMITE_PUB = 'Conformité Pub';
    
    global List<SBQQ__Subscription__c> start(Database.BatchableContext cnx) { 
         return [SELECT Id, CompanyAddressCity__c, OrderNumber__c, CompanyAddressCountry__c, CompanyPhone__c, ContactGender__c, ContactLastName__c, 
                 ContactFirstName__c, Companyindustry__c, CompanyName__c, PrintVolume__c, BroadcastSoftware__c, PromoterDescription__c, SBQQ_RequiredById__c,
                 FlowType__c, BroadcastPartner__c, PostalCode__c, Souscription_Conforme__c, ComplianceProcess__c, Status__c, AccessStoreState__c, 
                 ProductWorkflow__c, AccessUserId__c, KilometerRadius__c, AccessStoreId__c, CompanyAddressStreet__c, CompanyAddressZipcode__c, LeadPhone__c,
                 ContractEmail__c, CompanySegment__c, CompanySiret__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS
                 AND Souscription_Conforme__c = false];
    }
    
    global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {
        try {
            List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
            List<SBQQ__Subscription__c> subsMissingInformation = new List<SBQQ__Subscription__c>();
            List<Id> parentSubsIds = new List<Id>();
            for(SBQQ__Subscription__c sub : scope) {
               if (sub.ComplianceProcess__c == IMMO_NEUF) {
                    SBQQ__Subscription__c subImmo = setConformiteImmoNeuf(sub);                  
                    if (subImmo != null) {
                        subs.add(subImmo);
                        if (sub.SBQQ_RequiredById__c != null) {
                            parentSubsIds.add(sub.SBQQ_RequiredById__c);                      
                       }
                    }
                }
                if(sub.ComplianceProcess__c == CONFORMITE_PUB) {
                    if(sub.EffectiveEndDate__c > System.today() && isProcessfailed(sub)) {
                        sub.MissingInformations__c = true;
                        subsMissingInformation.add(sub);
                        List<SBQQ__Subscription__c> relatedSBQQ = addConcernedComplianceProcess(subsMissingInformation);
                        subsMissingInformation.addAll(relatedSBQQ);
                    }
                }
            }            
            subs.addAll(setParentConforme(parentSubsIds));
            update subs;
            update subsMissingInformation;
         
        } catch(Exception e) {
            Logs.error('SubscriptionComplianceCheck','Batch Compliance Check', e);
        }
    }
    
    global void finish(Database.BatchableContext cnx) {
    }
    private Boolean isProcessfailed(SBQQ__Subscription__c sub){
        Boolean processfailed = false;
        // treatment
        return processfailed;
    }

    private List<SBQQ__Subscription__c> addConcernedComplianceProcess(List<SBQQ__Subscription__c> subs){
        List<String> sBQQRequiredByIds = new List<String>();
        for(SBQQ__Subscription__c sub : subs){
            sBQQRequiredByIds.add(sub.SBQQ_RequiredById__c);
        }
        List<SBQQ__Subscription__c> result = [SELECT Id, Souscription_Conforme__c,SBQQ_RequiredById__c FROM SBQQ__Subscription__c WHERE ComplianceProcess__c = :CONFORMITE_PUB 
                                        AND ComplianceProcess__c =:IMMO_NEUF  AND (Id IN :sBQQRequiredByIds OR SBQQ_RequiredById__c IN :sBQQRequiredByIds )];
        for(SBQQ__Subscription__c sub : result){
             sub.MissingInformations__c = true;                               
       }
        return result;
    }

    private SBQQ__Subscription__c setConformiteImmoNeuf(SBQQ__Subscription__c sub) {
        if(sub.PromoterDescription__c != null && sub.FlowType__c != null && sub.ProductWorkflow__c != null
          && sub.ContractEmail__c != null && sub.CompanySiret__c != null && sub.CompanyName__c != null
          && sub.CompanyAddressStreet__c != null && sub.CompanyAddressZipcode__c != null && sub.CompanyAddressCity__c != null
          && sub.CompanyPhone__c != null && sub.ContactGender__c != null && sub.ContactFirstName__c != null 
          && sub.ContactLastName__c != null && sub.LeadPhone__c != null) {
            sub.Souscription_Conforme__c = true;
            return sub;
        }
        return null;
    }
    
    private SBQQ__Subscription__c[] setParentConforme(List<ID> parentSubsIds) {
           SBQQ__Subscription__c[] parentSubs = [SELECT Id, Souscription_Conforme__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS 
                                           AND Souscription_Conforme__c = false AND Id IN :parentSubsIds];
            if (parentSubs.size() > 0) {
                for(SBQQ__Subscription__c parentSub : parentSubs){
                     parentSub.Souscription_Conforme__c = true;
                }
            }
        return parentSubs;
    }
}