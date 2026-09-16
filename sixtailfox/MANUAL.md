# Manual steps

Things `setup.sh` can't do for you.

## Default shell + docker group

`setup.sh` runs `chsh` and `usermod -aG docker`, but both need a fresh login
to take effect.

```sh
# log out and back in (or reboot)
```

## Terminal font

Set your terminal emulator's font to **MesloLGS NF** (installed by the
`shell` stage). In Alacritty this is already set in `alacritty/alacritty.toml`;
other terminals need it set manually in their own preferences.

## Auth logins

```sh
gh auth login
gcloud auth login
```

## Machine-local secrets

Not in this repo. Create them if you need them; the rc files source them
only if present.

```sh
touch ~/.company_config ~/.bashrc.secrets
```

## Not scripted at all

Licensed / machine-specific, install by hand: MATLAB, Wolfram, CUDA, NVIDIA
drivers, Foxglove, CrowdStrike, cursor-agent, claude.
