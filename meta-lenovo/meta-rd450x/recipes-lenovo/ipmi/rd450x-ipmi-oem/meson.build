project(
    'rd450x-ipmi-oem',
    'cpp',
    version: '0.1',
    meson_version: '>=1.1.1',
    default_options: ['cpp_std=c++23', 'warning_level=3', 'werror=true'],
)

shared_library(
    'rd450xoemcmds',
    'rd450x_oem.cpp',
    dependencies: [
        dependency('libipmid'),
        dependency('phosphor-logging'),
        dependency('sdbusplus'),
    ],
    version: meson.project_version(),
    # The ipmid symbols are resolved when ipmid loads the provider.
    override_options: ['b_lundef=false'],
    install: true,
    install_dir: get_option('libdir') / 'ipmid-providers',
)
