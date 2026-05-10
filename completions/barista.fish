# Fish completion for barista

function __fish_barista_no_subcommand
  for token in (commandline -opc)
    switch $token
      case brew commands counter discard help house menu origin pantry pour restock serving setup table version-file
        return 1
    end
  end
  return 0
end

function __fish_barista_installed_versions
  barista menu --bare 2>/dev/null
  echo system
end

function __fish_barista_brew_completions
  set -l barista_dir "$BARISTA_DIR"
  if test -z "$barista_dir"
    set -l barista_bin (command -v barista 2>/dev/null)
    and set barista_dir (dirname (dirname $barista_bin))
  end
  set -l user_dir (barista pantry 2>/dev/null)/distributions
  set -l builtin_dir "$barista_dir/distributions"
  for dir in $builtin_dir $user_dir
    test -d $dir || continue
    for f in $dir/*.sh
      set -l name (basename $f .sh)
      echo $name
      echo "$name@lts"
      echo "$name@latest"
    end
  end
end

# Disable file completions for barista
complete -c barista -f

# Subcommands
complete -c barista -n __fish_barista_no_subcommand -a brew          -d 'Install a Java version'
complete -c barista -n __fish_barista_no_subcommand -a commands      -d 'List available commands'
complete -c barista -n __fish_barista_no_subcommand -a counter       -d 'Show the active Java version number'
complete -c barista -n __fish_barista_no_subcommand -a discard       -d 'Uninstall a Java version'
complete -c barista -n __fish_barista_no_subcommand -a help          -d 'Show help'
complete -c barista -n __fish_barista_no_subcommand -a house         -d 'Set or show the global Java version'
complete -c barista -n __fish_barista_no_subcommand -a menu          -d 'List installed Java versions'
complete -c barista -n __fish_barista_no_subcommand -a origin        -d 'Show where the active version is set'
complete -c barista -n __fish_barista_no_subcommand -a pantry        -d 'Show the barista root directory'
complete -c barista -n __fish_barista_no_subcommand -a pour          -d 'Run a command with the active Java version'
complete -c barista -n __fish_barista_no_subcommand -a restock       -d 'Rebuild shims'
complete -c barista -n __fish_barista_no_subcommand -a serving       -d 'Show the active Java version'
complete -c barista -n __fish_barista_no_subcommand -a setup         -d 'Configure shell integration'
complete -c barista -n __fish_barista_no_subcommand -a table         -d 'Set or show the local Java version'
complete -c barista -n __fish_barista_no_subcommand -a version-file  -d 'Find the .java-version file for the current directory'

# house / table / discard: installed versions
complete -c barista -n '__fish_seen_subcommand_from house table discard' \
  -a '(__fish_barista_installed_versions)'

# brew: distributions and aliases
complete -c barista -n '__fish_seen_subcommand_from brew' \
  -a '(__fish_barista_brew_completions)'
