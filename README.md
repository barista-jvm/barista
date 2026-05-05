# barista

Java version management, barista-style.

`barista` lets you switch between multiple JDK versions on a per-project or per-shell basis. It works by placing shim executables in front of your `PATH` and routing `java`, `javac`, and other JDK tools to the correct version based on a simple precedence chain.

---

## How it works

```
BARISTA_VERSION env var  (barista session)   ← highest priority
.java-version file       (barista table)
$BARISTA_ROOT/version    (barista house)
system Java                                  ← fallback
```

Installed JDKs live under `$BARISTA_ROOT/versions/` (default: `~/.barista/versions/`). Shim scripts in `~/.barista/shims/` intercept every Java tool call and forward it to the right version.

---

## Installation

```bash
git clone https://github.com/your-org/barista.git ~/.barista/barista

# Add to ~/.zshrc or ~/.bashrc:
export PATH="$HOME/.barista/barista/bin:$PATH"
eval "$(barista setup -)"
```

For fish shell, add to `~/.config/fish/config.fish`:

```fish
set -gx PATH "$HOME/.barista/barista/bin" $PATH
barista setup fish | source
```

Restart your shell (or `source ~/.zshrc`), then verify:

```bash
barista --version
```

---

## Commands

### `barista brew` — install a Java version

Downloads and installs a JDK via [Eclipse Temurin (Adoptium)](https://adoptium.net).

```bash
barista brew --list          # list available feature versions
barista brew 21              # install Java 21 (latest patch)
barista brew 17 --force      # reinstall even if already present
```

### `barista discard` — uninstall a Java version

```bash
barista discard 17           # prompts for confirmation
barista discard --force 11   # no prompt
```

### `barista menu` — list installed versions

```bash
barista menu                 # shows all versions; * marks the active one
barista menu --bare          # version names only
barista menu --skip-aliases  # omit symlinked versions
```

### `barista serving` — show active version

```bash
barista serving              # 21.0.3+9 (set by ~/.barista/version)
barista serving --bare       # 21.0.3+9
```

### `barista house` — set the global default

Writes to `$BARISTA_ROOT/version`. Applies everywhere unless overridden.

```bash
barista house                # show current global version
barista house 21             # set global version
barista house system         # reset to system Java
```

### `barista table` — set a per-directory version

Writes `.java-version` in the current directory. `barista` walks up the directory tree to find it.

```bash
barista table                # show local version
barista table 17             # set local version
barista table --unset        # remove .java-version
barista table 21 --force     # set without verifying it is installed
```

### `barista session` — set a version for the current shell

Overrides both `house` and `table` for the life of the shell session.

```bash
barista session 21           # export BARISTA_VERSION=21
barista session --unset      # clear the override
```

> Requires the shell function installed by `barista setup` to work correctly.

### `barista pour` — run a command with a specific version

Prepends the active version's `bin/` to `PATH`, then runs the command.

```bash
barista pour java -version
barista pour mvn package
```

### `barista origin` — find the active Java executable

```bash
barista origin java          # full path to java under the active version
barista origin javac --nosystem
```

### `barista counter` — show the install prefix

```bash
barista counter              # ~/.barista/versions/21.0.3+9
barista counter 17
```

### `barista pantry` — show BARISTA_ROOT

```bash
barista pantry               # /Users/you/.barista
```

### `barista restock` — regenerate shims

Run after installing or removing versions to keep shims in sync.

```bash
barista restock
```

### `barista setup` — print shell integration code

```bash
eval "$(barista setup -)"              # bash/zsh, PATH only
eval "$(barista setup bash)"           # bash, full integration
barista setup fish | source            # fish
barista setup --no-rehash bash         # skip rehash on shell start
```

### `barista version-file` — find the active version file

```bash
barista version-file         # path to the .java-version or global version file
barista version-file /some/dir
```

### `barista help` — command documentation

```bash
barista help                 # list all commands with summaries
barista help brew            # full usage for a specific command
```

### `barista --version`

```bash
barista --version            # barista 0.1.0
```

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `BARISTA_ROOT` | `~/.barista` | Root directory for versions and shims |
| `BARISTA_VERSION` | — | Shell-level version override (`barista session`) |
| `BARISTA_DEBUG` | — | Set to any value to enable `set -x` tracing |

---

## Project layout

```
barista/
├── bin/
│   └── barista               # entry point (symlink → execs/barista)
└── execs/
    ├── barista               # main dispatcher
    ├── barista---version
    ├── barista-brew
    ├── barista-commands
    ├── barista-counter
    ├── barista-discard
    ├── barista-help
    ├── barista-house
    ├── barista-menu
    ├── barista-origin
    ├── barista-pantry
    ├── barista-pour
    ├── barista-restock
    ├── barista-serving
    ├── barista-session
    ├── barista-setup
    ├── barista-sh-session    # shell function helper for session
    ├── barista-sh-table      # shell function helper for table
    ├── barista-table
    ├── barista-version-file
    ├── barista-version-file-read
    └── barista-version-file-write
```

Each file under `execs/` is a standalone executable script. The dispatcher routes `barista <command>` to `barista-<command>` by adding `execs/` to `PATH`.

---

## License

See [LICENSE](LICENSE).
