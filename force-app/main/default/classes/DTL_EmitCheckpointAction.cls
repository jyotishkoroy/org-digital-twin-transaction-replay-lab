/**
 * Flow Invocable Action: DTL_EmitCheckpoint
 */
public with sharing class DTL_EmitCheckpointAction {

    public class Request {
        @InvocableVariable(required=true)
        public String traceId;

        @InvocableVariable
        public Integer sequence;

        @InvocableVariable
        public String label;

        @InvocableVariable
        public String payloadJson;
    }

    @InvocableMethod(label='DTL Emit Checkpoint' description='Appends a semantic checkpoint to an existing trace.')
    public static void invoke(List<Request> requests) {
        for (Request r : requests) {
            DTL_TraceService.emitCheckpoint((Id) r.traceId, r.sequence, r.label, r.payloadJson);
        }
    }
}
