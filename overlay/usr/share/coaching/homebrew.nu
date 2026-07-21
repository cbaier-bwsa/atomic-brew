# /usr/share/coaching/homebrew.nu
# Homebrew-Umgebung für Nushell. Wird aus env.nu gesourct.

const brew_prefix = "/var/home/linuxbrew/.linuxbrew"

if ($brew_prefix | path exists) {
    $env.HOMEBREW_PREFIX = $brew_prefix
    $env.HOMEBREW_CELLAR = $"($brew_prefix)/Cellar"
    $env.HOMEBREW_REPOSITORY = $"($brew_prefix)/Homebrew"

    $env.PATH = ($env.PATH
        | split row (char esep)
        | prepend $"($brew_prefix)/sbin"
        | prepend $"($brew_prefix)/bin")

    $env.MANPATH = ([$"($brew_prefix)/share/man"] | append ($env.MANPATH? | default ""))
    $env.INFOPATH = ([$"($brew_prefix)/share/info"] | append ($env.INFOPATH? | default ""))
}
