# barista

<p align="center">
  <img src="docs/logo.svg" width="180" alt="barista logo"/>
</p>

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
git clone https://github.com/barista-jvm/barista.git ~/.barista/barista

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

Downloads and installs a JDK from a configured distribution (default: Eclipse Temurin / Adoptium).

```bash
barista brew --list                    # list all available dist@version values
barista brew adoptium@21               # install Java 21 from Eclipse Temurin
barista brew corretto@21               # install Java 21 from Amazon Corretto
barista brew openjdk@17                # install Java 17 from jdk.java.net
barista brew adoptium@21 --force       # reinstall even if already present
```

See [JDK distributions](#jdk-distributions) below for built-in options and how to add your own.

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

## JDK distributions

barista uses a plugin-style distribution system. Each distribution is a small bash script that tells barista where to download a JDK for a given version, OS, and architecture.

### Built-in distributions

| Name | Provider |
|---|---|
| `adoptium` | [Eclipse Temurin (Adoptium)](https://adoptium.net) — **default** |
| `corretto` | [Amazon Corretto](https://aws.amazon.com/corretto/) |
| `zulu` | [Azul Zulu](https://www.azul.com/downloads/) |
| `microsoft` | [Microsoft Build of OpenJDK](https://learn.microsoft.com/en-ca/java/openjdk/download) |
| `openjdk` | [OpenJDK (jdk.java.net)](https://jdk.java.net/archive/) |

### OpenJDK distribution

The `openjdk` distribution provides official OpenJDK builds from [jdk.java.net/archive](https://jdk.java.net/archive/).

**Version list** — `barista brew --list` scrapes the archive page live and shows the latest patch release per major version:

```
openjdk@26
openjdk@25.0.2
openjdk@24.0.2
openjdk@23.0.2
openjdk@21.0.2
...
openjdk@9.0.4
```

**Installing:**

```bash
barista brew openjdk@21      # installs the latest 21.x available in the archive
barista brew openjdk@23.0.2  # same result — version resolves to the latest 23.x
```

**Platform notes:**

| Platform | Versions with aarch64 builds |
|---|---|
| macOS | Java 17 and later |
| Linux | Java 16 and later |

Older versions (≤ Java 15) only have `x64` builds. Requesting an unavailable combination prints a clear error and exits without downloading.

**URL resolution** — unlike other distributions, every install and `--list` call fetches [jdk.java.net/archive](https://jdk.java.net/archive/) at runtime, because each release URL contains a unique hash that cannot be predicted. Ensure network access is available when using this distribution.

### Adding a custom distribution

Create a file at `$BARISTA_ROOT/distributions/<name>.sh` (default: `~/.barista/distributions/<name>.sh`). A user-defined file with the same name as a built-in overrides it.

The script must define:

- **`DIST_NAME`** — human-readable label shown in output
- **`dist_url(feature_version, os, arch)`** — echoes the download URL for the given Java major version, OS (`mac` or `linux`), and architecture (`x64` or `aarch64`)
- **`dist_list()`** _(optional)_ — prints available versions (one per line) shown by `barista brew --list`

**Minimal example** — a private mirror with a predictable URL pattern:

```bash
# ~/.barista/distributions/internal.sh
DIST_NAME="Acme Internal JDK Mirror"

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  printf 'https://jdk.internal.acme.com/jdk-%s-%s-%s.tar.gz' \
    "$feature_version" "$os" "$arch"
}

dist_list() {
  echo "Available versions:"
  echo "  17"
  echo "  21"
}
```

**Advanced example** — resolving the URL via an API call:

```bash
# ~/.barista/distributions/myregistry.sh
DIST_NAME="My JDK Registry"
REGISTRY_API="https://jdk-registry.internal.acme.com/api"

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  curl -sf "${REGISTRY_API}/latest?version=${feature_version}&os=${os}&arch=${arch}" \
    | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"//'
}

dist_list() {
  echo "Fetching versions from registry..."
  curl -sf "${REGISTRY_API}/versions" | grep -oE '[0-9]+'
}
```

The archive barista downloads must be a `.tar.gz`. After extraction, if a `Contents/Home/` subdirectory is present (common in macOS Adoptium tarballs), barista automatically promotes it to the version root.

Once created, verify the distribution is recognised:

```bash
barista brew --list          # → ... internal@17, internal@21 ...
barista brew internal@21
```

### Distribution metadata

barista records which distribution was used to install each version:

```
~/.barista/versions/adoptium@21/.barista-dist   # contains: adoptium
~/.barista/versions/openjdk@23.0.2/.barista-dist  # contains: openjdk
```

---

## License

See [LICENSE](LICENSE).
