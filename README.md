# aat-kiwi-descriptions

Builds image appliances via KIWI-NG. For now, only Debian is supported but I plan to add more distributions.
Images are built for various architectures. I recommend using Docker for foreign platforms which are not compatible
with the host architecture.

Apart from usual kiwi configurations, there is some configuration mangling (.in files) via `Makefile`, so I would not recommend
tweaking configurations directly unless you know what you are doing. Take a look especially at `make help`.

*bsp* folder is a board support packaging folder: it stores tweaks that some software may need in order to work well with
the machine in question. Upstreaming configurations should be the norm, but sometimes this configuration may not be upstreamable,
hence putting in here. I recommend running `make bsp-pull` periodically.

## Build

    make <platform> DISTRO=<debian|alpine|pmos> TIER=<workstation|server> [RELEASE=<release>] [COMPRESS=0|1] [LOCALE=<locale>] [TIMEZONE=<timezone>] [KEYTABLE=<keytable>] [USERNAME=<name>] [PASSWORD=<password>]

### With Docker

    make docker-pc-x86_64 DISTRO=debian TIER=workstation

Foreign-arch platforms need QEMU binfmt registered on the host, once:

    docker run --privileged --rm tonistiigi/binfmt --install all

## Output

See `build/<platform>_<distro>-<release>-<arch>-<tier>_<version>.img.xz` (or `.img` if built with `COMPRESS=0`); `<version>` is a build timestamp (`YYYYMMDDHHmmss`).

## Layout

- `components/<distro>/*.xml`: package lists per distro
- `platforms/*.xml`: per-device settings and packages
- `preferences/`, `repositories/`, `users/`: distro-wide config, package sources, default account
- `includes/profiles.xml`: how platform, distro, and tier combine
- `bsp/`: device overlay files, fetch updates via `make bsp-pull`
- `scripts/`: build helpers (fetch/apply BSP, finalize image, lint profile order)
- `config.xml.in`, `config.sh`, `post_bootstrap.sh.in`, `pre_disk_sync.sh`: image description and chroot scripts (`.in` files are mangled by `Makefile` before use)
- `docker-compose.yml`, `Dockerfile`: builder container definition

## References

- [KIWI-NG](https://github.com/OSInside/kiwi): image builder
- [Docker](https://www.docker.com/): isolated builds
- [xmllint](http://xmlsoft.org/): XML validation and formatting
- [shellcheck](https://www.shellcheck.net/): shell script linting
- [shfmt](https://github.com/scop/shfmt): shell script formatting
- [QEMU](https://www.qemu.org/): foreign architecture emulation

## License

[LICENSE](LICENSE)
