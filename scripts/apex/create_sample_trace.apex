/**
 * Seeds a sample trace (APEX transaction) that is deterministic and side-effect free.
 * Run:
 *   sfdx force:apex:execute -f scripts/apex/create_sample_trace.apex -u <alias>
 */
DTL_SampleTransaction.CaptureRequest req = new DTL_SampleTransaction.CaptureRequest();
req.a = 12;
req.b = 30;
req.threshold = 40;
DTL_SampleTransaction.capture(req);
System.debug('DTL sample trace created.');
