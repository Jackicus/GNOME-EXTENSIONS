# The user's session, and the nested shell

The user works in the real GNOME session while the extensions are developed. Everything a
test does happens in a nested shell or not at all.

- **Nested shell only.** `./scripts/nested.sh start` (AI Usage: `./scripts/dev.sh nested`)
  runs a complete second GNOME Shell, headless, with its own session bus and virtual
  monitor, reading the same installed extensions. An exception in `enable()` takes down the
  nested shell, never the user's. `start` opens a live mirror window on the real desktop
  (a PipeWire screencast) so the user can watch: two people are looking, you through
  screenshots and the user through the mirror.
- **Stop it when done**, a failed check included: `./scripts/nested.sh stop` (`make
  nested-stop`) closes the mirror, the shell, its bus and every process it started, and
  says whether anything survived; read that line. The SessionEnd hook and an idle timeout
  are backstops for accidents, not the plan.
- **Never touch another repository's nested shell.** Several can run at once, one per
  repository, each with its own Wayland display and `$XDG_RUNTIME_DIR/<name>-nested/` run
  directory. Never stop, kill or `pkill` one but this repository's.
- **Never `pkill -f`** a pattern that appears in your own command line, the real
  session's processes or another nested shell's. Kill by pid, or through the nested
  shell's own commands.
- **dconf is shared.** A plain `start` reads and writes the user's real dconf: each
  `dconf-service` caches the database at start and rewrites the whole file on its next
  write, so the last writer wins with a stale copy, and `start` itself may write
  `enabled-extensions`. Where the repository has it, use **`start --clean`**: a database
  of its own, the real session's look copied in, nothing written to
  `~/.config/dconf/user`. Without it, change settings before `start` or after `stop`,
  never while another nested shell is up (`ls $XDG_RUNTIME_DIR/*-nested`), and put back
  what you changed. Wrap nested `gsettings` calls in `timeout`.
- **Real side effects stay real.** A launch from the nested shell (Play, Show in Files,
  `xdg-open steam://…`) reaches the user's machine; an online scan with `--from-settings`
  reads the user's real API keys and goes to the network; a virtual pad from uinput is a
  device for the whole machine; the "Allow inhibiting shortcuts" answer is written to the
  real permission store. Do none of these to test unless the task asks, and undo what you
  did.
- **Secrets.** API keys and tokens live in dconf or in other tools' files in plain text.
  Never log them, print them, put them on a command line or paste them into the
  conversation.
- **Public repositories.** Nothing of the user's real data goes into a commit: no library
  titles, account names, paths of their files, or screenshots of their own collection.
  Committed screenshots are of `--clean` (and `--demo`, where a repository has invented
  data) nested shells only.
- **`Eval` is off** in the nested shell. Drive it with input, screenshots and D-Bus, as a
  user would. Screenshots and banners borrow `org.gnome.SettingsDaemon.MediaKeys` on the
  throwaway bus because the shell refuses unknown callers; never try that on the real bus.
- **The real session is the user's to restart.** A new UUID, an edit to
  `./scripts/dev-extension.js` or `metadata.json`, needs a logout in the real session: say
  so, never log anyone out. The nested shell picks them up with `stop` + `start`.
