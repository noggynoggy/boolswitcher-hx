# boolswitcher.hx

A vibecoded [Helix](https://github.com/helix-editor/helix) plugin for switching and toggling booleans, written for the [Steel](https://github.com/mattwparas/steel) plugin system.

## Features

- **3 Conversion Modes**:
  - `switch-boolean`: Toggle boolean values (e.g. `true` $\leftrightarrow$ `false`, `1` $\leftrightarrow$ `0`, `yes` $\leftrightarrow$ `no`, `y` $\leftrightarrow$ `n`).
  - `set-boolean-positive`: Turn boolean values positive (e.g. `false` $\rightarrow$ `true`, `0` $\rightarrow$ `1`).
  - `set-boolean-negative`: Turn boolean values negative (e.g. `true` $\rightarrow$ `false`, `1` $\rightarrow$ `0`).

## Installation

### With helix-plugins-nix

Add to your `plugins` attribute set in your Nix configuration (e.g. via home-manager or Hjem) as described in [helix-plugins-nix](https://codeberg.org/maxschipper/helix-plugins-nix#adding-plugins-that-are-not-packaged-here):

```nix
programs.helix.plugins = {
  "boolswitcher.hx" = pkgs.fetchFromGitHub {
    owner = "me";
    repo = "boolswitcher-hx";
    rev = "newset or smth";
    hash = "some-hash";
  };
};
```

This copies all `.scm` files into `~/.local/share/steel/cogs/boolswitcher.hx`.

### With forge

[forge](https://github.com/mattwparas/steel) is the Steel package manager:

```sh
forge pkg install --git https://github.com/<owner>/boolswitcher-hx
```

I never tested this

### Manual Installation

Copy the repository into your Steel cogs directory:

```sh
mkdir -p ~/.local/share/steel/cogs/boolswitcher.hx
cp -r * ~/.local/share/steel/cogs/boolswitcher.hx/
```
I never tested this either

## Configuration

Require `boolswitcher.hx/boolswitcher.scm` in `~/.config/helix/init.scm` and bind the commands or create a sub-keymap:

```scheme
(require "boolswitcher.hx/boolswitcher.scm")
(require (only-in "helix/keymaps.scm" add-global-keybinding))

;; Sub-mode for booleans
(define bool-mode
  (hash "s" ":switch-boolean"
        "p" ":set-boolean-positive"
        "n" ":set-boolean-negative"))

(add-global-keybinding (hash "normal" (hash "ü" bool-mode)
                             "select" (hash "ü" bool-mode)))
```

## Commands

| Command | Alias | Description |
| --- | --- | --- |
| `:switch-boolean` | `:toggle-boolean` | Toggles boolean (e.g. `true` $\leftrightarrow$ `false`) |
| `:set-boolean-positive` | `:set-boolean-true` | Sets boolean to positive (`false` $\rightarrow$ `true`) |
| `:set-boolean-negative` | `:set-boolean-false` | Sets boolean to negative (`true` $\rightarrow$ `false`) |

## Supported Keywords

| Positive | Negative |
| --- | --- |
| `true` | `false` |
| `True` | `False` |
| `TRUE` | `FALSE` |
| `yes` | `no` |
| `Yes` | `No` |
| `YES` | `NO` |
| `y` | `n` |
| `Y` | `N` |
| `1` | `0` |

## Testing

Run the test suite with `steel`:

```sh
steel test.scm
```
