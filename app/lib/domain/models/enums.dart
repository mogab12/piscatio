/// Enum names are persisted as text: renaming a value requires a migration.
library;

/// Who may see a trip's location. `friends` behaves like `private` until the
/// social features exist (Phase 3).
enum PrivacyLevel { private, friends, approximate, exact }

/// `rejected`: the server refused the row (invalid); it is sent again only
/// after the next local edit.
enum SyncStatus { pending, synced, rejected }

enum BaitType { natural, artificial, fly, other }

enum GearType { combo, rod, reel, line, other }
