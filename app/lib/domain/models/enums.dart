/// Enum names are persisted as text: renaming a value requires a migration.
library;

/// Who may see a trip's location. `friends` behaves like `private` until the
/// social features exist (Phase 3).
enum PrivacyLevel { private, friends, approximate, exact }

enum SyncStatus { pending, synced }

enum BaitType { natural, artificial, fly, other }

enum GearType { combo, rod, reel, line, other }
