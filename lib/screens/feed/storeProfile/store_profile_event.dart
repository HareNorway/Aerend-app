sealed class StoreProfileEvent {
  const StoreProfileEvent();
}

class StoreProfileInitRequested extends StoreProfileEvent {
  const StoreProfileInitRequested();
}

class StoreProfileRefreshRequested extends StoreProfileEvent {
  const StoreProfileRefreshRequested();
}

class StoreProfileFollowToggleRequested extends StoreProfileEvent {
  const StoreProfileFollowToggleRequested();
}

class StoreProfileVisitStoreRequested extends StoreProfileEvent {
  const StoreProfileVisitStoreRequested();
}
