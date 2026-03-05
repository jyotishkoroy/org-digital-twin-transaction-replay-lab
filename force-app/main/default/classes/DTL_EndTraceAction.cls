/**
 * Flow Invocable Action: DTL_EndTrace
 */
public with sharing class DTL_EndTraceAction {

    public class Request {
        @InvocableVariable(required=true)
        public String traceId;

        @InvocableVariable
        public String expectedOutputsJson;
    }

    @InvocableMethod(label='DTL End Trace' description='Finalizes a trace with expected outputs for later diffing.')
    public static void invoke(List<Request> requests) {
        for (Request r : requests) {
            DTL_TraceService.endTrace((Id) r.traceId, r.expectedOutputsJson);
        }
    }
}
