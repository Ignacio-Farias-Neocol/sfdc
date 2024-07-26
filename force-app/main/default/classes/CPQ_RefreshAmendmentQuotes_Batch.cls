public class CPQ_RefreshAmendmentQuotes_Batch implements Database.Batchable<SObject>, Database.Stateful {
    public String quoteId;

    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<SBQQ__Quote__c> quotes = [Select ID, SBQQ__Account__c From SBQQ__Quote__c Where ID =: quoteId and SBQQ__Primary__c = TRUE and SBQQ__Type__c = 'Amendment' and SBQQ__Account__c <> NULL];
        if (quotes.isEmpty()) {
            return null;
        }

        Set<String> oppIds = new Set<String>();
        for (Opportunity o : [Select ID, (Select ID From SBQQ__Quotes2__r Where SBQQ__Type__c = 'Amendment') 
                            From Opportunity 
                            Where AccountId =: quotes[0].SBQQ__Account__c and 
                                StageName Not in ('Closed Won', 'Closed Lost')/* and 
                                Business_Group__c = 'MSP'*/]) {
            if (!o.SBQQ__Quotes2__r.isEmpty()) {
                oppIds.add(o.Id);
            }
        }
    
        System.Debug('*** oppIds ' + oppIds);
        
        String SOQL = 'Select ID From Opportunity Where ID in: oppIds';
        return Database.getQueryLocator(SOQL);
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> oppties){
        Integer lastKey = 100;

        for (Opportunity o : oppties) {
            System.Debug('*** process opp ' + o.Id);

        //QuoteModel
        //-------------------------------------------------
            Set<String> quoteFields = LightningUtility.getCustomFieldNames(SBQQ__Quote__c.getSObjectType(), false);
            quoteFields.add('Name');
            String query = LightningUtility.buildObjectQuery(quoteFields, 'CurrencyIsoCode', 'Id=\'' + quoteId + '\'', 'SBQQ__Quote__c');
            SBQQ__Quote__c quote = (SBQQ__Quote__c)database.query(query);

            QuoteModel qm = new QuoteModel();
            qm.record = quote.clone(false, false, false, false);
            qm.record.SBQQ__Opportunity2__c = o.Id;
            qm.record.SBQQ__Primary__c = false;
            qm.record.SBQQ__Source__c = quoteId;

            qm.nextKey = lastKey;
            
            //qm.applyAdditionalDiscountLast = qm.record.ApplyAdditionalDiscountLast__c;
            //qm.applyPartnerDiscountFirst = qm.record.ApplyPartnerDiscountFirst__c;
            //qm.channelDiscountsOffList = qm.record.ChannelDiscountsOffList__c;
            //qm.customerTotal = qm.record.SBQQ__CustomerAmount__c;
            //qm.netTotal = qm.record.SBQQ__NetAmount__c;

        //QuoteLineGroupModel
        //-------------------------------------------------
            qm.lineItemGroups = new List<QuoteLineGroupModel>();
            Map<String, Integer> qlgkeyMaps = new Map<String, Integer>();

            Set<String> quoteGroupFields = LightningUtility.getCustomFieldNames(SBQQ__QuoteLineGroup__c.getSObjectType(), false);
            quoteGroupFields.add('Name');
            query = LightningUtility.buildObjectQuery(quoteGroupFields, 'CurrencyIsoCode', 'SBQQ__Quote__c=\'' + quoteId + '\'', 'SBQQ__QuoteLineGroup__c');
            for (SBQQ__QuoteLineGroup__c g : (List<SBQQ__QuoteLineGroup__c>)database.query(query)) {
                lastKey = lastKey + 10;

                QuoteLineGroupModel qlgm = new QuoteLineGroupModel();
                qlgm.record = g.clone(false, false, false, false);
                qlgm.record.SBQQ__Quote__c = null;
                qlgm.record.SBQQ__Source__c = g.Id;

                qlgm.key = lastKey;

                qm.lineItemGroups.add(qlgm);
                qlgkeyMaps.put(g.Id, qlgm.key);
            }

        //QuoteLineModel
        //-------------------------------------------------
            qm.lineItems = new List<QuoteLineModel>();
            Map<String, Integer> qlkeyMaps = new Map<String, Integer>();

            Set<String> quoteLineFields = LightningUtility.getCustomFieldNames(SBQQ__QuoteLine__c.getSObjectType(), false);
            query = LightningUtility.buildObjectQuery(quoteLineFields, 'CurrencyIsoCode', 'SBQQ__Quote__c=\'' + quoteId + '\'', 'SBQQ__QuoteLine__c');
            for (SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>)database.query(query)) {
                lastKey = lastKey + 10;

                QuoteLineModel qlm = new QuoteLineModel();
                qlm.record = ql.clone(false, false, false, false);
                qlm.record.SBQQ__Quote__c = null;
                qlm.record.SBQQ__Source__c = ql.Id;

                qlm.key = lastKey;
                qlm.parentGroupKey = qlgkeyMaps.get(ql.SBQQ__Group__c);

                lastKey = qlm.key;

                qm.lineItems.add(qlm);
                qlkeyMaps.put(ql.Id, qlm.key);
            }
    
            for (QuoteLineModel qlm : qm.lineItems) {
                qlm.parentItemKey = qlkeyMaps.get(qlm.record.SBQQ__RequiredBy__c);
            }
            
            String sqmStr = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(qm));
            System.Debug('*** sqmStr ' + sqmStr);
            //QuoteModel sqm = (QuoteModel)JSON.deserialize(sqmStr, QuoteModel.class);
            //System.Debug('*** sqm ' + sqm);
        }
    }

    public void finish(Database.BatchableContext BC){}
}
/*
CPQ_RefreshAmendmentQuotes_Batch b = new CPQ_RefreshAmendmentQuotes_Batch();//
b.quoteId = 'a1Y5x000008pXV6EAM';
database.executebatch(b, 1);
*/