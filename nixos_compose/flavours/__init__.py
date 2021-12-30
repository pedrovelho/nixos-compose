"""
   nixos_compose.flavours
   Adapted from pygments project (pygments.styles)
   :copyright: Copyright 2006-2021 by the Pygments team, see AUTHORS.
    :license: BSD, see LICENSE for details.
"""

#: Maps flavour names to 'submodule::classname'.
FLAVOUR_MAP = {
    "docker": "docker::DockerFlavour",
    "vm-ramdisk": "vm_ramdisk::VmRamdiskFlavour",
    "nixos-test": "nixos_test::NixosTestFlavour",
    "nixos-test-ssh": "nixos_test::NixosTestSshFlavour",
    "g5k-ramdisk": "grid5000::G5kRamdiskFlavour",
    "g5k-image": "grid5000::G5KImageFlavour",
}


class ClassNotFound(ValueError):
    """Raised if one of the lookup functions didn't find a matching class."""


def get_flavour_by_name(name):
    if name in FLAVOUR_MAP:
        mod, cls = FLAVOUR_MAP[name].split("::")

    try:
        mod = __import__("nixos_compose.flavours." + mod, None, None, [cls])
    except ImportError:
        raise ClassNotFound(f"Could not find flavour module {mod}")
    try:
        return getattr(mod, cls)
    except AttributeError:
        raise ClassNotFound(f"Could not find flavour class {cls} in flavour module.")
