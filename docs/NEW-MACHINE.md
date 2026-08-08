# Before wiping the old machine

The install steps live in the [README](../README.md). This page is the other
half: what is deliberately *not* in this repo and therefore has to come across
by hand.

## Secrets and keys

- [ ] `~/.ssh/` — the keys and your real `config`. Move them over an encrypted
      channel, then run `install/ssh-setup.sh` on the new machine to fix
      permissions and load them into the keychain.

      **`ht` is the one that matters** — 3072-bit RSA, referenced five times in
      your config, the only key the agent holds, and what the HPC, VDI and
      deNBI hosts plus GitHub authenticate against. It has no passphrase.
      `id_rsa` (2048-bit, comment `jug@myers-mac-8.local`, passphrase-protected)
      is from an older laptop and nothing references it. `jugf.pem`/`.ppk` is an
      AWS/PuTTY pair with no config entry. Carry `ht`; decide deliberately about
      the other two rather than copying them by reflex.
- [ ] **The plaintext secrets that accumulated in `~/.ssh`** —
      `ngrok_recovery_codes.txt`, `Matrix_security-key.txt`,
      `Recovery_HT_BioRender_Authenticator.txt`, and a Google
      `client_secret_*.json`. These belong in a password manager, not on the
      new disk.
- [ ] `~/.config/gh/hosts.yml` — or simply run `gh auth login` again.
- [ ] Licence files: Gurobi (`gurobi.lic`), Adobe, TeamViewer, iStat Menus.

## Work you might lose

- [ ] Uncommitted or unpushed changes in your repo directories:

      for d in ~/GIT/*/ ~/git/*/; do git -C "$d" status --short --branch; done

- [ ] Any conda environment you still need. `--from-history` gives you what you
      actually asked for rather than the full dependency closure:

      conda env export --from-history -n <env>

      See [conda-to-uv.md](conda-to-uv.md) for translating it into a uv project.

- [ ] Mac App Store apps, if you want them back by ID:

      brew install mas && mas list

## Settings with no file to copy

- [ ] **Terminal.app profile** — never was in git. Export it from
      Terminal → Settings → Profiles → Export if you want it, or take the
      opportunity to move to Ghostty/iTerm2.
- [ ] **Karabiner-Elements** — `~/.config/karabiner` exists on the old machine
      but the app itself is gone. Stale; deliberately not carried over.
- [ ] **Spectacle** — unmaintained for years. `Brewfile.apps` lists Rectangle,
      its successor, instead. Its shortcuts will need setting up again.

## Applications that aren't casks

Everything else in `Brewfile.apps` installs itself. These don't:

| | |
|---|---|
| Trello | trello.com/platforms |
| FileZilla Pro | purchased, via filezilla-project.org |
| reMarkable desktop | remarkable.com/software |
| VMware Horizon Client | institute VDI |
| kDrive (Infomaniak) | infomaniak.com/en/apps/download-kdrive |
| HT Self Service, FortiClient, Avaya Workplace | institute-managed |
| Publish or Perish, Speechify, GoodNotes, Kindle | Mac App Store |
