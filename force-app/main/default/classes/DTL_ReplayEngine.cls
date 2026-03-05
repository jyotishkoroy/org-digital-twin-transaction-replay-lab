/**
 * Orchestrates trace replay and diffing.
 */
public with sharing class DTL_ReplayEngine {

    public class ReplayResult {
        @AuraEnabled public Id traceId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String replayOutputsJson;
        @AuraEnabled public String diffJson;
        @AuraEnabled public String statusMessage;
    }

    public static ReplayResult replay(Id traceId) {
        if (traceId == null) throw new DTL_Exceptions.ValidationException('traceId is required.');
        DTL_Security.requireRead(DTL_Trace__c.SObjectType);

        DTL_Trace__c t = [
            SELECT Id, TraceType__c, FlowApiName__c, ReplayClass__c, InputsJson__c, ExpectedOutputsJson__c
            FROM DTL_Trace__c
            WHERE Id = :traceId
            LIMIT 1
        ];

        ReplayResult r = new ReplayResult();
        r.traceId = t.Id;

        try {
            Map<String, Object> inputs = DTL_Json.parseObject(t.InputsJson__c);
            Map<String, Object> expected = DTL_Json.parseObject(t.ExpectedOutputsJson__c);

            Map<String, Object> actual;
            if (t.TraceType__c == 'FLOW') {
                Set<String> outKeys = new Set<String>();
                outKeys.addAll(expected.keySet());
                DTL_FlowRunner.FlowRunResult fr = DTL_FlowRunner.run(t.FlowApiName__c, inputs, outKeys);
                actual = fr.outputs;
                r.statusMessage = fr.statusMessage;
            } else if (t.TraceType__c == 'APEX') {
                actual = runReplayableApex(t.ReplayClass__c, inputs);
                r.statusMessage = 'Apex replay completed.';
            } else {
                throw new DTL_Exceptions.ReplayException('Unknown TraceType__c: ' + t.TraceType__c);
            }

            List<Map<String, Object>> diffs = DTL_DiffUtil.diff(expected, actual);

            r.success = (diffs.isEmpty());
            r.replayOutputsJson = DTL_Json.stringify(actual);
            r.diffJson = DTL_Json.stringify(diffs);

            DTL_TraceService.recordReplayResult(
                t.Id,
                r.success,
                r.replayOutputsJson,
                r.diffJson,
                r.statusMessage
            );

            return r;
        } catch (Exception e) {
            r.success = false;
            r.statusMessage = e.getMessage();
            r.replayOutputsJson = '{}';
            r.diffJson = '[]';
            DTL_TraceService.recordReplayResult(t.Id, false, r.replayOutputsJson, r.diffJson, r.statusMessage);
            return r;
        }
    }

    private static Map<String, Object> runReplayableApex(String className, Map<String, Object> inputs) {
        if (String.isBlank(className)) {
            throw new DTL_Exceptions.ReplayException('ReplayClass__c is required for APEX traces.');
        }

        Type t = Type.forName(className);
        if (t == null) throw new DTL_Exceptions.ReplayException('Replay class not found: ' + className);

        Object o = t.newInstance();
        if (!(o instanceof DTL_ReplayableTransaction)) {
            throw new DTL_Exceptions.ReplayException('Replay class must implement DTL_ReplayableTransaction.');
        }

        DTL_ReplayableTransaction rt = (DTL_ReplayableTransaction) o;
        Map<String, Object> safeInputs = (inputs == null) ? new Map<String, Object>() : inputs;
        return rt.execute(safeInputs);
    }
}
