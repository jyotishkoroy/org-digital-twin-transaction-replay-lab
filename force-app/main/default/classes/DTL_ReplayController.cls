/**
 * UI controller for dtlReplayRunner.
 */
public with sharing class DTL_ReplayController {

    public class TraceRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String traceType;
        @AuraEnabled public String status;
        @AuraEnabled public String transactionName;
        @AuraEnabled public Datetime capturedAt;
        @AuraEnabled public Datetime replayRanAt;
        @AuraEnabled public String statusMessage;
    }

    public class TraceDetail {
        @AuraEnabled public Id id;
        @AuraEnabled public String traceType;
        @AuraEnabled public String status;
        @AuraEnabled public String transactionName;
        @AuraEnabled public String flowApiName;
        @AuraEnabled public String replayClass;
        @AuraEnabled public String inputsJson;
        @AuraEnabled public String contextJson;
        @AuraEnabled public String expectedOutputsJson;
        @AuraEnabled public String replayOutputsJson;
        @AuraEnabled public String replayDiffJson;
        @AuraEnabled public Datetime capturedAt;
        @AuraEnabled public Datetime replayRanAt;
        @AuraEnabled public String statusMessage;
        @AuraEnabled public List<CheckpointRow> checkpoints;
    }

    public class CheckpointRow {
        @AuraEnabled public Integer sequence;
        @AuraEnabled public String label;
        @AuraEnabled public String payloadJson;
        @AuraEnabled public Datetime createdDate;
    }

    @AuraEnabled(cacheable=true)
    public static List<TraceRow> listTraces(Integer limitSize) {
        if (limitSize == null || limitSize <= 0 || limitSize > 200) limitSize = 50;
        DTL_Security.requireRead(DTL_Trace__c.SObjectType);

        List<DTL_Trace__c> traces = [
            SELECT Id, Name, TraceType__c, Status__c, TransactionName__c, CapturedAt__c, ReplayRanAt__c, ReplayStatusMessage__c
            FROM DTL_Trace__c
            ORDER BY CapturedAt__c DESC NULLS LAST, CreatedDate DESC
            LIMIT :limitSize
        ];

        List<TraceRow> out = new List<TraceRow>();
        for (DTL_Trace__c t : traces) {
            TraceRow r = new TraceRow();
            r.id = t.Id;
            r.name = t.Name;
            r.traceType = t.TraceType__c;
            r.status = t.Status__c;
            r.transactionName = t.TransactionName__c;
            r.capturedAt = t.CapturedAt__c;
            r.replayRanAt = t.ReplayRanAt__c;
            r.statusMessage = t.ReplayStatusMessage__c;
            out.add(r);
        }
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static TraceDetail getTraceDetail(Id traceId) {
        if (traceId == null) throw new DTL_Exceptions.ValidationException('traceId is required.');
        DTL_Security.requireRead(DTL_Trace__c.SObjectType);
        DTL_Security.requireRead(DTL_Checkpoint__c.SObjectType);

        DTL_Trace__c t = [
            SELECT Id, Name, TraceType__c, Status__c, TransactionName__c, FlowApiName__c, ReplayClass__c,
                   InputsJson__c, ContextJson__c, ExpectedOutputsJson__c, ReplayOutputsJson__c, ReplayDiffJson__c,
                   CapturedAt__c, ReplayRanAt__c, ReplayStatusMessage__c
            FROM DTL_Trace__c
            WHERE Id = :traceId
            LIMIT 1
        ];

        TraceDetail d = new TraceDetail();
        d.id = t.Id;
        d.traceType = t.TraceType__c;
        d.status = t.Status__c;
        d.transactionName = t.TransactionName__c;
        d.flowApiName = t.FlowApiName__c;
        d.replayClass = t.ReplayClass__c;
        d.inputsJson = String.isBlank(t.InputsJson__c) ? '{}' : t.InputsJson__c;
        d.contextJson = String.isBlank(t.ContextJson__c) ? '{}' : t.ContextJson__c;
        d.expectedOutputsJson = String.isBlank(t.ExpectedOutputsJson__c) ? '{}' : t.ExpectedOutputsJson__c;
        d.replayOutputsJson = String.isBlank(t.ReplayOutputsJson__c) ? '{}' : t.ReplayOutputsJson__c;
        d.replayDiffJson = String.isBlank(t.ReplayDiffJson__c) ? '[]' : t.ReplayDiffJson__c;
        d.capturedAt = t.CapturedAt__c;
        d.replayRanAt = t.ReplayRanAt__c;
        d.statusMessage = t.ReplayStatusMessage__c;

        d.checkpoints = new List<CheckpointRow>();
        for (DTL_Checkpoint__c cp : [
            SELECT Sequence__c, Label__c, PayloadJson__c, CreatedDate
            FROM DTL_Checkpoint__c
            WHERE Trace__c = :traceId
            ORDER BY Sequence__c ASC, CreatedDate ASC
            LIMIT 500
        ]) {
            CheckpointRow c = new CheckpointRow();
            c.sequence = Integer.valueOf(cp.Sequence__c);
            c.label = cp.Label__c;
            c.payloadJson = String.isBlank(cp.PayloadJson__c) ? '{}' : cp.PayloadJson__c;
            c.createdDate = cp.CreatedDate;
            d.checkpoints.add(c);
        }
        return d;
    }

    @AuraEnabled
    public static DTL_ReplayEngine.ReplayResult replayTrace(Id traceId) {
        return DTL_ReplayEngine.replay(traceId);
    }
}
