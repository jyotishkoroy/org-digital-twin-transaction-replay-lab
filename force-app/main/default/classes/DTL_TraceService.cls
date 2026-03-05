/**
 * Trace SDK backend.
 *
 * Core idea: trace is the container; checkpoints are ordered semantic events.
 */
public with sharing class DTL_TraceService {

    public class StartRequest {
        public String traceType; // FLOW or APEX
        public String transactionName;
        public String flowApiName;
        public String replayClass;
        public String inputsJson;
        public String contextJson;
    }
    public class StartResponse {
        public Id traceId;
    }

    public static Id startTrace(StartRequest req) {
        if (req == null) throw new DTL_Exceptions.ValidationException('StartRequest is required.');
        if (String.isBlank(req.traceType)) throw new DTL_Exceptions.ValidationException('traceType is required.');

        String t = req.traceType.trim().toUpperCase();
        if (t != 'FLOW' && t != 'APEX') {
            throw new DTL_Exceptions.ValidationException('Unsupported traceType: ' + req.traceType);
        }

        DTL_Security.requireCreate(DTL_Trace__c.SObjectType);

        DTL_Trace__c trace = new DTL_Trace__c();
        trace.TraceType__c = t;
        trace.Status__c = 'CAPTURED';
        trace.TransactionName__c = String.isBlank(req.transactionName) ? 'Unnamed Transaction' : req.transactionName;
        trace.FlowApiName__c = req.flowApiName;
        trace.ReplayClass__c = req.replayClass;
        trace.InputsJson__c = String.isBlank(req.inputsJson) ? '{}' : req.inputsJson;
        trace.ContextJson__c = String.isBlank(req.contextJson) ? '{}' : req.contextJson;
        trace.CapturedAt__c = System.now();
        trace.CapturedBy__c = UserInfo.getUserId();
        trace.SourceOrgId__c = UserInfo.getOrganizationId();

        trace = (DTL_Trace__c) DTL_Security.stripForInsert(trace);
        insert trace;

        return trace.Id;
    }

    public static void emitCheckpoint(Id traceId, Integer sequence, String label, String payloadJson) {
        if (traceId == null) throw new DTL_Exceptions.ValidationException('traceId is required.');
        if (sequence == null || sequence <= 0) sequence = nextSequence(traceId);
        if (String.isBlank(label)) label = 'Checkpoint ' + String.valueOf(sequence);

        DTL_Security.requireCreate(DTL_Checkpoint__c.SObjectType);

        DTL_Checkpoint__c cp = new DTL_Checkpoint__c();
        cp.Trace__c = traceId;
        cp.Sequence__c = sequence;
        cp.Label__c = label;
        cp.PayloadJson__c = String.isBlank(payloadJson) ? '{}' : payloadJson;

        cp = (DTL_Checkpoint__c) DTL_Security.stripForInsert(cp);
        insert cp;
    }

    public static void endTrace(Id traceId, String expectedOutputsJson) {
        if (traceId == null) throw new DTL_Exceptions.ValidationException('traceId is required.');
        DTL_Security.requireUpdate(DTL_Trace__c.SObjectType);

        DTL_Trace__c t = [
            SELECT Id, Status__c
            FROM DTL_Trace__c
            WHERE Id = :traceId
            LIMIT 1
        ];
        t.ExpectedOutputsJson__c = String.isBlank(expectedOutputsJson) ? '{}' : expectedOutputsJson;
        t = (DTL_Trace__c) DTL_Security.stripForUpdate(t);
        update t;
    }

    public static void recordReplayResult(Id traceId, Boolean success, String replayOutputsJson, String diffJson, String statusMessage) {
        if (traceId == null) throw new DTL_Exceptions.ValidationException('traceId is required.');
        DTL_Security.requireUpdate(DTL_Trace__c.SObjectType);

        DTL_Trace__c t = new DTL_Trace__c(
            Id = traceId,
            Status__c = success ? 'REPLAYED' : 'FAILED',
            ReplayOutputsJson__c = String.isBlank(replayOutputsJson) ? '{}' : replayOutputsJson,
            ReplayDiffJson__c = String.isBlank(diffJson) ? '[]' : diffJson,
            ReplayRanAt__c = System.now(),
            ReplayStatusMessage__c = statusMessage
        );
        t = (DTL_Trace__c) DTL_Security.stripForUpdate(t);
        update t;
    }

    private static Integer nextSequence(Id traceId) {
        AggregateResult ar = [
            SELECT MAX(Sequence__c) m
            FROM DTL_Checkpoint__c
            WHERE Trace__c = :traceId
        ];
        Object m = ar.get('m');
        Integer max = (m == null) ? 0 : Integer.valueOf(String.valueOf(m));
        return max + 1;
    }
}
