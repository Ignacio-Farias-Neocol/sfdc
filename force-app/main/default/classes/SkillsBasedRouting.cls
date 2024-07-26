/**
* @author Jose Vega
* @date 2018
*
* @description This class handles routing cases to agents based on skill required.
* This class leverages two metadata objects Skill__mdt and Skill_Mapping__mdt.
*/
public with sharing class SkillsBasedRouting {
    @InvocableMethod
    public static void routeUsingSkills(List<String> cases) {
        
        List<Case> caseObjects = Database.query('SELECT ' + getCaseFields() + ' FROM Case Where Id IN :cases');
        
        for (Case caseObj : caseObjects) {
            try {
                // Create a PendingServiceRouting to initiate routing
                createPendingServiceRouting(caseObj);
            } catch(exception e) {
                System.debug('ERROR:' + e.getStackTraceString());
                throw e;
            }
        }
    }
    
    static void createPendingServiceRouting(Case caseObj) {
    
        List<PendingServiceRouting> existingPsrObj = [SELECT Id FROM PendingServiceRouting WHERE WorkItemId = :caseObj.Id];
        
        if (existingPsrObj.isEmpty()) {

            PendingServiceRouting psrObj = new PendingServiceRouting(
                CapacityWeight = 1,
                IsReadyForRouting = FALSE,
                RoutingModel  = 'MostAvailable',
                RoutingPriority = 1,
                RoutingType = 'SkillsBased',
                ServiceChannelId = getChannelId(),
                WorkItemId = caseObj.Id,
                PushTimeout = 0
            );
            insert psrObj;
            psrObj = [select id, IsReadyForRouting from PendingServiceRouting where id = : psrObj.id];
            
            Map<Skill, Decimal> skillList = getSkills(caseObj);
            
            System.debug('~~ skillList ~~' + skillList);
            
            List<SkillRequirement> listSkillRequirement = new List<SkillRequirement>();
            for (Skill skill: skillList.keySet()) {
                SkillRequirement srObj = new SkillRequirement(
                    RelatedRecordId = psrObj.id,
                    SkillId = skill.Id,
                    SkillLevel = skillList.get(skill)
                );
                listSkillRequirement.add(srObj);
               
            }

            if(!listSkillRequirement.isEmpty()){
                insert listSkillRequirement;
            }
            
            psrObj.IsReadyForRouting = TRUE;
            update psrObj;
        }
    }
    
    static String getChannelId() {
        ServiceChannel channel = [Select Id From ServiceChannel Where RelatedEntity = 'Case'];
        return channel.Id;
    }
    
    @TestVisible
    static String getCaseFields() {
        Skill__mdt[] skills = [Select Skill_Source_Field_API_Name__c FROM Skill__mdt WHERE Is_Active__c = true];

        List<String> caseFields = new List<String>();
        
        // Defaults to always request Id
        caseFields.add('Id');
        
        for (Skill__mdt skill : skills) {
            caseFields.add(skill.Skill_Source_Field_API_Name__c);
        }

        String result = caseFields[0];
        caseFields.remove(0);
        while(!caseFields.isEmpty()) {
            result += ',' + caseFields[0];
            caseFields.remove(0);
        }
        
        return result;
    }
    
    
     /*******************************************************************************************************
    * @description Returns a map that has the skill and level needed to support the case
    * @param Case
    * @return the describe field result for the given field
    * @example
    * { 'ENG' : 1, 'Firewall' : 5 }
    */
    @TestVisible
    static Map<Skill, Decimal> getSkills(Case supportCase) {
        Map<String, String> skillName = new Map<String, String>(); 
        Skill__mdt[] skills = [Select Skill_Level__c, Skill_Type__c, Skill_Source_Field_API_Name__c FROM Skill__mdt WHERE Is_Active__c = true];

        Map<String, Map<String, String>> skillMap = new Map<String, Map<String, String>>();
        
        for (Skill__mdt skill : skills) {
            Map<String, String> skillMeta = new Map<String, String>();
            skillMeta.put('skill_source_field_api_name', skill.Skill_Source_Field_API_Name__c);
            skillMeta.put('skill_level', String.valueOf(skill.Skill_Level__c));
            
            skillMap.put(skill.Skill_Type__c, skillMeta);
        }
        
        Skill_Mapping__mdt[] skillMappings = [Select Skill_Type__c, Skill_Type_Value__c, Skill_Name__c FROM Skill_Mapping__mdt];
        
        for (Skill_Mapping__mdt skillMapping: skillMappings) {
            String skillMappingType = skillMapping.Skill_Type__c;
            
            // It's possible this is empty because not all Skills could be active.
            Map<String, String> skillMeta = skillMap.get(skillMappingType);
            
            if ( skillMeta != null &&  !skillMeta.isEmpty()) {
            
                String fieldApiName = skillMeta.get('skill_source_field_api_name');
                String skillLevel = skillMeta.get('skill_level');
                
                System.debug('~~ fieldApiName ~~' + fieldApiName);
                
                Object ObjFieldApiValue;
                try {
                    ObjFieldApiValue = supportCase.get(fieldApiName);
                    System.debug('~~ ObjfieldApiValue ~~' + ObjFieldApiValue);
                } catch(exception e) {
                    ObjFieldApiValue = '';
                    System.debug('ERROR:' + e.getStackTraceString());
                }
                    
                String fieldApiValue = '';
                if (ObjFieldApiValue != null) {
                    fieldApiValue = ObjFieldApiValue.toString();
                }
            
                System.debug('~~ fieldApiValue ~~' + fieldApiValue);
    
                
                if (fieldApiValue.contains(skillMapping.Skill_Type_Value__c)) {
                    skillName.put(skillMapping.Skill_Name__c, skillLevel);
                }
            }
        }
        
        Map<Skill, Decimal> skillsRequired = new Map<Skill, Decimal>();
        Map<String, Skill> skillsMap = new Map<String, Skill>();

        for(Skill sk : [Select Id, DeveloperName From Skill Where DeveloperName = :skillName.keySet()]){
            skillsMap.put(sk.DeveloperName, sk);
        } 
        
        for (String skillRequiredName: skillName.keySet()) {
			if(skillsMap.containsKey(skillRequiredName) && skillName.containsKey(skillRequiredName)){
				skillsRequired.put(skillsMap.get(skillRequiredName), decimal.valueOf(skillName.get(skillRequiredName)));
			}
				
        }

        // List<Skill> skillsRequired = [Select Id From Skill Where DeveloperName IN :skillName];
        
        return skillsRequired;
    }
    
}