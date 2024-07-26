public virtual class RuleEngine {

    private static final String CLT = 'Less Than';
    private static final String CGT = 'Greater Than';
    private static final String CEQ = 'Equal To';
    private static final String CNQ = 'Not Equal To';
    private static final String CCN = 'Contains';
    private static final String CNC = 'Not Contains';
    private static final String ICG = 'Is Changed';
    private static final String CNT = 'Changed To';
    private static final String CCC = 'Changed Contains';
    private static final String WTH = 'Within';
    private static final String CWH = 'Changed Within';
    public static final String STR = '"';


    private static final Pattern PDEC = (Pattern.compile('^[-+]?\\d+(\\.\\d*)?$'));


    public static DisplayType getFieldType(SObject record, String fieldName){

        Map<String, Schema.SObjectField> objectFields = record.getSObjectType().getDescribe().fields.getMap();
        // Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(record.getSObjectType().getDescribe().getName()).getDescribe().fields.getMap();
        DisplayType targetFieldType = objectFields.get(fieldName).getDescribe().getType();

        return targetFieldType;

    }

    public static List <Decimal> objsToDecimals(List <Object> objs){

        List <Decimal> decimals = new List <Decimal>();
        for (Object o: objs){
            decimals.add( (decimal) o );
        }
        return decimals;
    }

    public static List <String> objsToStrings(List <Object> objs){

        List <String> strings = new List <String>();
        for (Object o: objs){
            strings.add(String.valueOf(o));
        }
        return strings;
    }

    public static List <Boolean> objsToBooleans(List <Object> objs){

        List <Boolean> booleans = new List <Boolean>();
        for (Object o: objs){
            booleans.add(Boolean.valueOf(o));
        }
        return booleans;
    }

    public void setTargetValue(SObject record, String fieldName, String stringValue) {

        // 07-20: check if the stringValue is actual a field name or not
        try {
            stringValue = String.valueOf(record.get(stringValue));
            System.debug('~~ stringValue :' +  stringValue);

        } catch (Exception e) {
            System.debug('~~ stringValue ' + stringValue + 'is not a fieldName');
        }


        DisplayType targetFieldType = getFieldType(record, fieldName);

        System.debug('~~ Target Field: ' + fieldName + ' ~~ Value: ' + stringValue);

        if (targetFieldType == Schema.DisplayType.Boolean) {
            Boolean bValue = Boolean.valueOf(stringValue);
            record.put(fieldName, bValue);
        } else if (targetFieldType == Schema.DisplayType.Double && isDecimal(stringValue)) {
            Decimal dValue = Decimal.valueOf(stringValue);
            record.put(fieldName, dValue);
        } else if ( targetFieldType == Schema.DisplayType.DATETIME){
            if (StringValue.contains('NOW')){
                record.put(fieldName, Datetime.now());
            } else {
                Datetime v = Datetime.valueOf(stringValue);
                record.put(fieldName, v);
            }
        } else {
            record.put(fieldName, stringValue);
        }

    }


    protected Object getValueAsObject(SObject record, String ruleActual) {

        // Make sure value is casted as its "real" type before converting back to a generic Object,
        // so that the underlying data will have the correct instanceof later

        Object actualValue;
    
        if (String.isNotBlank(ruleActual)) {
            if (ruleActual.equalsIgnoreCase('null')){  // 2018-02-13 handle null validation
                // convert null value as empty string
                actualValue = '';
            } else if (isDecimal(ruleActual)) {
                // evaluate as a real number
                actualValue = Decimal.valueOf(ruleActual);
            }
            else if (ruleActual.startsWith(STR)) {
                // use literal string value sans STR identifier
                String rawValue = ruleActual.substring(STR.length());
                if (rawValue.endsWith(STR)) {
                    rawValue = rawValue.substring(0, rawValue.length() - STR.length());
                }
                actualValue = rawValue;
            }
            else {
                try {
                    // use value found in referenced field
                    actualValue = record.get(ruleActual);
                    if (actualValue == null) {
                        actualValue = '';  // if the value is null, set as empty string
                    }
                }
                catch (System.Exception ex) {
                    // just assume null
                }
            }
        }
    
        return actualValue;

    }

    protected Boolean compare(Object actual, Object oldActual, Object expect, String operator ){

        Boolean evaluation = false;
        if (operator == ICG){
            evaluation = isChanged(actual, oldActual);
        } else if (operator == CNT) {

            // first check if it is changed, next check if the new value match with the new one
            if (isChanged(actual, oldActual)){
                evaluation = compare(actual, expect, CEQ);
            }

        } else if (operator == CCC) {

            // first check if it is changed, next check if the new value contains
            if (isChanged(actual, oldActual)){
                evaluation = compare(actual, expect, CCN);
            }

        } else if (operator == CWH) {

            // first check if it is changed, next check if the new value contains
            if (isChanged(actual, oldActual)){
                evaluation = compare(actual, expect, WTH);
            }

        } else {
            evaluation = compare(actual, expect, operator);
        }

        return evaluation;

    }

    protected Boolean isChanged(Object actual, Object oldActual){
        Boolean evaluation = false;

        // for is changed operation, null and empty string is considered to be the same
        String strActual = (actual == null) ? '' : String.valueOf(actual);
        String strOldActual = (oldActual == null ) ? '':  String.valueOf(oldActual);
        evaluation = ( strActual != strOldActual);

        return evaluation;

    }

    protected Boolean compare(Object a, Object b, String c) {

        // System.debug(' ~~ compare: actual=' + a  + ' operator:' + c + ' expected:' + b);

        Boolean evaluation = false;
        Boolean contains = false;
        Boolean valueIn = false;
        Integer comparison = 0;

        // Note: in getValueAsObject, the null value should be property converted to empty string .
        // so if either object is null, assume wrong setup and exit
        if (a == null || b == null){ // 2018-01-07 - exit if either object is null.
            return evaluation;
        }

        // Both values must be a number to be compared as such. Any other mix will treat both as strings.
        // Need to use explicit data types here as generic Objects cannot be compared with the < (or >) operator.
        if (a instanceof Decimal && b instanceof Decimal) {

            Decimal x = (Decimal)a;
            Decimal y = (Decimal)b;

            comparison = x == y ? 0 : x < y ? -1 : 1;

        }
        else {

            String x = String.valueOf(a);
            String y = String.valueOf(b);

            List<String> v = new List <String>();
            for (String s: y.split(',')){
                v.add(s.trim());
            }

            comparison = x == y ? 0 : x < y ? -1 : 1;
            contains = String.isNotBlank(x) && x.contains(y);
            valueIn = v.contains(x.trim());  // use trimed data in the within operation

//            System.debug('~~ v-' + v + '-');
//            System.debug('~~ w-' + w + '-');
//            System.debug('~~ x-' + x + '-');
//            System.debug('~~ y-' + y + '-');
//            System.debug('~~ z-' + z + '-');

        }


        // run each comparison, and then pull specific one.  avoids heavy if-branching
        Map<String,Boolean> comparisons = new Map<String,Boolean> {
            CLT => comparison == -1, // expected < actual
            CGT => comparison ==  1, // expected > actual
            CEQ => comparison ==  0, // expected == actual
            CNQ => comparison !=  0, // expected != actual
            CCN => contains,         // actual.contains(expected)
            CNC => !contains,         // !actual.contains(expected)
            WTH => valueIn   // actual.in (expected list)
        };

        if (comparisons.containsKey(c)) {
            evaluation = comparisons.get(c);
        }

        return evaluation;

    }

    protected Boolean isDecimal(String value) {
        // the built-in String method isNumeric only returns True for Integers, ie. 123
        // this will appropriately check for an Integer OR Decimal pattern, ie. 12.3
        return String.isNotBlank(value) && (value.isNumeric() || PDEC.matcher(value).find());
    }

}