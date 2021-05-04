---
slug: install-declarative
---

If you use [NixOS](https://nixos.org/), add the following to your `environment.systemPackages` list:


```nix
(let
   neuronSrc = builtins.fetchTarball "https://github.com/srid/neuron/archive/master.tar.gz";
   neuronPkg = import neuronSrc;
 in neuronPkg.default)
```

If you use [home-manager](https://github.com/rycee/home-manager), add the above to your `home.packages` list.

## Pinning versions

It is generally recommended to pin your imports in Nix. The above expression will fetch the then `master` branch, which is not what you want for reproducibility. Pick a revision from [the commit history](https://github.com/srid/neuron/commits/master), and then use it, for example:

```nix
# Use this for neuron 0.5 or above only.
(let neuronRev = "GITREVHERE";
   neuronSrc = builtins.fetchTarball "https://github.com/srid/neuron/archive/${neuronRev}.tar.gz";
   neuronPkg = import neuronSrc;
 in neuronPkg.default)
```

In the future if you decide to upgrade neuron, simply change the revision hash to a newer one.

## Flakes

[Flakes](https://nixos.wiki/wiki/Flakes) is supported, and you can use neuron via the URL `github:srid/neuron`. For eg., `nix run github:srid/neuron` will run neuron off the master branch on GitHub.

## Systemd service

If you use [home-manager](https://github.com/rycee/home-manager), you can also
run neuron as a systemd service; see [[home-manager systemd service]]#.
