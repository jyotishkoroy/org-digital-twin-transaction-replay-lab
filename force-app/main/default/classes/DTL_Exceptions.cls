/**
 * Org Digital Twin + Transaction Replay Lab
 * Copyright 2026 Jyotishko Roy
 * Licensed under Apache-2.0 (see LICENSE)
 */
public class DTL_Exceptions {
    public class DtlException extends Exception {}
    public class SecurityException extends DtlException {}
    public class ValidationException extends DtlException {}
    public class ReplayException extends DtlException {}
}
