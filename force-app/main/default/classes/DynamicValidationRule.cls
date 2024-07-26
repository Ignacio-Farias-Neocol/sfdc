public interface DynamicValidationRule {

    Set<String> getExpectedFields();
    Map<SObject,Boolean> evaluateRule(List<SObject> records);

}