/**
 * Centralized CRUD/FLS checks + stripInaccessible utilities.
 */
public class DTL_Security {

    public static void requireCrud(Boolean canAccess, String message) {
        if (!canAccess) {
            throw new DTL_Exceptions.SecurityException(message);
        }
    }

    public static void requireCreate(Schema.SObjectType sType) {
        requireCrud(sType.getDescribe().isCreateable(), 'No create access for ' + sType.getDescribe().getName());
    }
    public static void requireRead(Schema.SObjectType sType) {
        requireCrud(sType.getDescribe().isAccessible(), 'No read access for ' + sType.getDescribe().getName());
    }
    public static void requireUpdate(Schema.SObjectType sType) {
        requireCrud(sType.getDescribe().isUpdateable(), 'No update access for ' + sType.getDescribe().getName());
    }
    public static void requireDelete(Schema.SObjectType sType) {
        requireCrud(sType.getDescribe().isDeletable(), 'No delete access for ' + sType.getDescribe().getName());
    }

    public static SObject stripForInsert(SObject record) {
        return Security.stripInaccessible(Security.AccessType.CREATABLE, new List<SObject>{record}).getRecords()[0];
    }

    public static List<SObject> stripForInsert(List<SObject> records) {
        return Security.stripInaccessible(Security.AccessType.CREATABLE, records).getRecords();
    }

    public static SObject stripForUpdate(SObject record) {
        return Security.stripInaccessible(Security.AccessType.UPDATABLE, new List<SObject>{record}).getRecords()[0];
    }

    public static List<SObject> stripForUpdate(List<SObject> records) {
        return Security.stripInaccessible(Security.AccessType.UPDATABLE, records).getRecords();
    }
}
