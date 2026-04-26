/// Server-wins conflict resolution.
/// Returns true if the server record should overwrite the local record.
bool serverWins(int localLastModifiedMs, int serverLastModifiedMs) {
  return serverLastModifiedMs > localLastModifiedMs;
}
