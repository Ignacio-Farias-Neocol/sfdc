/**
* @author Aditya Padhy
* @date 2021-12-22
*
* @group ElapseTimeCalcRuleOpptyCoreBefore
* @group-content
*
* @description:
*   SFDC-14523 CORE ONLY: Total Time to Response (TTR) for Opportunities Reporting in SFDC	
*/

public class ElapseTimeCalcRuleOpptyCoreBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        if (triggerContext.contains('Update')) {
            Opportunity oldOppRec;
            List<Opportunity> listOfFilteredOpps = new List<Opportunity>();
            for(Opportunity opp : (List<Opportunity>)records){
                oldOppRec = (Opportunity)oldRecordMap.get(opp.Id);
                if(opp.First_Respond_Time__c != oldOppRec.First_Respond_Time__c && opp.First_Respond_Time__c != null){
                    listOfFilteredOpps.add(opp);
                }
            }
            if(!listOfFilteredOpps.isEmpty()){
                calculateElapseTime(listOfFilteredOpps);
            }
        }
    }
    public void calculateElapseTime(List<Opportunity> listOfOpps){
		Set<Id> setOfUserIds = new Set<Id>();
		Map<Id, User> mapOfUsers = new Map<Id, User>();
		Timezone tz;
		Datetime created;
		String createdInOppOwnersTime;
		Datetime createdInOppOwnersTimeZone;
		Datetime responded;
		Datetime respondedInOppOwnersTimeZone;
		Decimal daysBetween1;
		Decimal noOfWeekdays1;
		Decimal noOfWeekdays2;
		Decimal noOfWeekdaysFirstFINAL;
		Integer createdHour;
		Integer createdMin;
		Integer respondedMin;
		String createdDayOfWeek;
		String respondedInOppOwnersTime;
		String respondedDayOfWeek;
        Integer respondedHour;
        Datetime endOfDayOnCreated;
		for(Opportunity opp : listOfOpps){
			setOfUserIds.add(opp.OwnerId);
		}
		
		for(User u : [SELECT Id, TimeZoneSidKey FROM user WHERE Id IN: setOfUserIds]){
			mapOfUsers.put(u.Id, u);
		}
		
        for(Opportunity opp : listOfOpps){
            //get the opp owner
            User u = mapOfUsers.get(opp.OwnerId);       
            //get logged in users timezone
            tz = Timezone.getTimeZone(u.TimeZoneSidKey);
            //get created and responded dates - these will always be in GMT 
            created = opp.CreatedDate;
            //get datetime string in opp owners timezone format
            createdInOppOwnersTime = created.format('yyyy-MM-dd HH:mm:ss',u.TimeZoneSidKey);
            createdInOppOwnersTimeZone = Datetime.valueOfGmt(createdInOppOwnersTime);
            createdHour = createdInOppOwnersTimeZone.hourGmt();
            //if the hour GMT > 17 or < 8 then adjust the created time accordinlgy
            if(createdHour > 17)
                createdInOppOwnersTimeZone = Datetime.newInstanceGmt(createdInOppOwnersTimeZone.yearGmt(),createdInOppOwnersTimeZone.monthGmt(),createdInOppOwnersTimeZone.dayGmt(),17,0,0);
            if(createdHour < 8)
                createdInOppOwnersTimeZone = Datetime.newInstanceGmt(createdInOppOwnersTimeZone.yearGmt(),createdInOppOwnersTimeZone.monthGmt(),createdInOppOwnersTimeZone.dayGmt(),8,0,0);
            createdMin = createdInOppOwnersTimeZone.minuteGmt();
            createdDayOfWeek = createdInOppOwnersTimeZone.format('E');
            responded = opp.First_Respond_Time__c;
            respondedInOppOwnersTime = responded.format('yyyy-MM-dd HH:mm:ss',u.TimeZoneSidKey);
            respondedInOppOwnersTimeZone = Datetime.valueOfGmt(respondedInOppOwnersTime);
            respondedHour = respondedInOppOwnersTimeZone.hourGmt();
            
            if(respondedHour > 17)
                respondedInOppOwnersTimeZone = Datetime.newinstanceGmt(respondedInOppOwnersTimeZone.yearGmt(),respondedInOppOwnersTimeZone.monthGmt(),respondedInOppOwnersTimeZone.dayGmt(),17,0,0);
            if(respondedHour < 8)
                respondedInOppOwnersTimeZone = Datetime.newinstanceGmt(respondedInOppOwnersTimeZone.yearGmt(),respondedInOppOwnersTimeZone.monthGmt(),respondedInOppOwnersTimeZone.dayGmt(),8,0,0);
            respondedMin = respondedInOppOwnersTimeZone.minuteGmt();
            respondedDayOfWeek = respondedInOppOwnersTimeZone.format('E');
            //Get number of weekdays between two dates - createdInOppOwnersTimeZone and respondedInOppOwnersTimeZone
            
            /*
            (5 * ( FLOOR( ( date_1 - DATE( 1900, 1, 8) ) / 7 ) ) + MIN( 5, MOD( date_1 - DATE( 1900, 1, 8), 7 ) ) )
            -
            (5 * ( FLOOR( ( date_2 - DATE( 1900, 1, 8) ) / 7 ) ) + MIN( 5, MOD( date_2 - DATE( 1900, 1, 8), 7 ) ) )
            
            date_1 = respondedInOppOwnersTimeZone
            date_2 = createdInOppOwnersTimeZone
            */
            daysBetween1 = Datetime.newinstance(1900,1,8).date().daysbetween(respondedInOppOwnersTimeZone.date());
            noOfWeekdays1 = 5 * Math.floor(daysBetween1/7);
            /** noOfWeekdays1 ==  (5 * ( FLOOR( ( date_1 - DATE( 1900, 1, 8) ) / 7 ) ) */ 
            noOfWeekdays2 = Math.mod(Datetime.newinstance(1900,1,8).date().daysbetween(respondedInOppOwnersTimeZone.date()),7);
            system.debug('-----noOfWeekdays2-----' + noOfWeekdays2);
            
            Decimal noToChoose;
            if(5<noOfWeekdays2)
                noToChoose = 5;
            else 
                noToChoose = noOfWeekdays2;
            /** noToChoose ==  MIN( 5, MOD( date_1 - DATE( 1900, 1, 8), 7 ) )*/
            noOfWeekdaysFirstFINAL = noOfWeekdays1 + noToChoose;
            Decimal daysBetween11 = Datetime.newinstance(1900,1,8).date().daysbetween(createdInOppOwnersTimeZone.date());
            Decimal noOfWeekdays11 = 5 * Math.floor(daysBetween11/7);
            /** noOfWeekdays11 == (5 * ( FLOOR( ( date_2 - DATE( 1900, 1, 8) ) / 7 ) ) */
            Decimal noOfWeekdays22 = Math.mod((Datetime.newinstance(1900,1,8).date().daysbetween(createdInOppOwnersTimeZone.date())),7);
            Decimal noToChoose1;
            if(5<noOfWeekdays22)
                noToChoose1 = 5;
            else 
                noToChoose1 = noOfWeekdays22;
            /** noToChoose1 == MIN( 5, MOD( date_2 - DATE( 1900, 1, 8), 7 ) )  */
            Decimal noOfWeekdaysSecondFINAL = noOfWeekdays11 + noToChoose1;
            //Total No. of weekdays
            Decimal TotalNoOfWeekdays = noOfWeekdaysFirstFINAL - noOfWeekdaysSecondFINAL;
            system.debug('---TotalNoOfWeekdays -----' + TotalNoOfWeekdays);
            
            //Calculate the no. of minutes
            //If created and responded are the same day
            if(TotalNoOfWeekdays == 0){
                Decimal seconds = (respondedInOppOwnersTimeZone.getTime() - createdInOppOwnersTimeZone.getTime())/1000;
                Decimal mins = seconds/60;
                opp.Time_elapsed_till_first_response_mins__c = mins;
            }
            
            //If Responded is on the next business day
            if(TotalNoOfWeekdays == 1){
                
                //CREATED
                endOfDayOnCreated = Datetime.newinstanceGmt(createdInOppOwnersTimeZone.year(), createdInOppOwnersTimeZone.month(), createdInOppOwnersTimeZone.day(), 17, 0,0);
                Decimal createdDateSecs = (endOfDayOnCreated.getTime() - createdInOppOwnersTimeZone.getTime())/1000;
                Decimal createdDateMins = createdDateSecs/60;
                //RESPONDED
                Datetime startOfDayforResponded = Datetime.newinstanceGmt(respondedInOppOwnersTimeZone.year(), respondedInOppOwnersTimeZone.month(), respondedInOppOwnersTimeZone.day(), 08, 0,0);
                //Decimal respondedDateSecs = (startOfDayforResponded.getTime() - respondedInOppOwnersTimeZone.gettime())/1000;
                Decimal respondedDateSecs = (respondedInOppOwnersTimeZone.getTime() - startOfDayforResponded.gettime())/1000;
                Decimal respondedDateMins = respondedDateSecs/60;
                Decimal totalMins = createdDateMins + respondedDateMins;
                opp.Time_elapsed_till_first_response_mins__c = totalMins;
            }
            
            if(TotalNoOfWeekdays > 1){
                //CREATED
                endOfDayOnCreated = Datetime.newinstanceGmt(createdInOppOwnersTimeZone.year(), createdInOppOwnersTimeZone.month(), createdInOppOwnersTimeZone.day(), 17, 0,0);
                Decimal createdDateSecs = (endOfDayOnCreated.getTime() - createdInOppOwnersTimeZone.getTime())/1000;
                Decimal createdDateMins = createdDateSecs/60;
                //FULL Weekday MINS
                Decimal totalNoOfWeekdaysbetweenCreatedAndResponded = TotalNoOfWeekdays - 1;
                Decimal noOfWorkingMins = totalNoOfWeekdaysbetweenCreatedAndResponded * 540;
                //RESPONDED
                Datetime startOfDayforResponded = Datetime.newinstanceGmt(respondedInOppOwnersTimeZone.year(), respondedInOppOwnersTimeZone.month(), respondedInOppOwnersTimeZone.day(), 08, 0,0);
                //Decimal respondedDateSecs = (startOfDayforResponded.getTime() - respondedInOppOwnersTimeZone.gettime())/1000;
                Decimal respondedDateSecs = (respondedInOppOwnersTimeZone.getTime() - startOfDayforResponded.gettime())/1000;
                Decimal respondedDateMins = respondedDateSecs/60;
                Decimal totalOverallMins = createdDateMins + noOfWorkingMins + respondedDateMins;
                opp.Time_elapsed_till_first_response_mins__c = totalOverallMins;
            }
        }
    }

}