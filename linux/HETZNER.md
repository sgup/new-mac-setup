# Hetzner Linux development box

Reusable runbook for an always-on Ubuntu development host reached over Tailscale,
SSH, and mosh. Project-specific build and deployment instructions belong in each
project's own repository.

## Choosing the server

The Hetzner CX line is EU-only (Germany and Finland). A Singapore or Ashburn box
therefore requires the more expensive CPX line for comparable cores and memory.
From UTC+8, Helsinki measured about 230 ms round-trip; use mosh so local echo hides
most of that latency.

Start with Ubuntu 26.04 on a `cx33` or larger. Several concurrent coding-agent
processes benefit from 2–4 GiB of swap; Hetzner images ship without it.

## Bootstrap

1. Select every SSH key that should have access **when creating the server**.
   Hetzner does not inject project keys added after a server already exists.
2. If cloud-init defines `users:`, include `- default`. Omitting it suppresses
   Hetzner's default user and SSH-key injection and can leave the web console as
   the only way in.
3. Create a non-root user, grant sudo access, confirm key-based SSH works, and then
   disable SSH password authentication (`PasswordAuthentication no`).
4. Install Tailscale:

   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

5. Confirm access over the tailnet, then close public port 22 in the Hetzner
   firewall. A host holding GitHub and coding-agent credentials should not expose
   SSH publicly.
6. Install the shared Linux shell and command-line environment:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/sgup/new-mac-setup/master/linux/provision.sh | bash
   ```

7. Install the host tools not owned by the shared dotfiles: `tmux`, `mosh`, Node,
   `gh`, Claude Code, and Codex. Authenticate interactively with `gh auth login`
   and `claude auth login`; never copy credential files into a repository.
8. Add swap, clone the projects needed on the host, and follow each project's
   remote-development runbook.

## SSH key trap

Do not assume the key offered by an SSH agent is one of the keys published on a
GitHub profile. A password-manager SSH agent may hold a separate key. Compare the
public keys from `ssh-add -L` with the server's `authorized_keys` before closing
the initial session. Seed the server from the union of the Hetzner-injected keys
and any agent-only key that should have access.

Put a short alias near the top of the client `~/.ssh/config`, before a broad
`Host *` block that might select a different agent or identity:

```sshconfig
Host devbox
  HostName <tailscale-hostname>
  User <user>
  ServerAliveInterval 30
  ServerAliveCountMax 6
```

## Working sessions

```bash
mosh devbox                 # or: ssh devbox
tmux new -A -s main         # attach if present, otherwise create
```

Detach with `Ctrl-b d`; reattach with `tmux attach -t main`. Mosh survives IP
changes and cellular dropouts, which makes it the better terminal transport from
a phone or on a high-latency connection.

cmux can add remote browser panes, drag-and-drop copy, and notifications over
`cmux ssh devbox`. If its installed build does not support a mosh transport, use
plain mosh when typing latency matters and cmux's SSH workspace when its extra
integrations matter more.

## Rebuild checklist

- SSH key injection selected during server creation
- non-root sudo user; password authentication disabled
- Tailscale access proven before public SSH is closed
- 2–4 GiB swap present
- dotfiles provisioner completed
- Node, `gh`, Claude Code, Codex, tmux, and mosh installed
- GitHub and coding-agent logins completed interactively
- project repositories cloned; project-specific remote runbooks followed
