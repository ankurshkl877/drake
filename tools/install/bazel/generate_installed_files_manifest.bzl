load("@drake//tools/install:install.bzl", "InstallInfo")
load("@drake//tools/skylark:pathutils.bzl", "basename")
load("@python//:version.bzl", "PYTHON_SITE_PACKAGES_RELPATH")

def _impl(ctx):
    known_non_runfiles = [
        # These are installed in share/drake, but are not runfiles (at least,
        # not with these paths).
        "manipulation/models/iiwa_description/iiwa_stack.LICENSE.txt",
        "setup/Brewfile",
        "setup/install_prereqs",
        "setup/packages-focal.txt",
        "setup/packages-jammy.txt",
        "setup/requirements.txt",
        # These are installed in share/drake and are runfiles for certain
        # targets, but none of those targets are relevant for this use case.
        "setup/deepnote/install_nginx",
        "setup/deepnote/install_xvfb",
        "setup/deepnote/nginx-meshcat-proxy.conf",
        "setup/deepnote/xvfb",
    ]
    known_non_runfiles_basenames = [
        "LICENSE",
        "LICENSE.TXT",
        "LICENSE.txt",
    ]
    known_non_runfiles_dirnames = [
        "tutorials/",
    ]
    drake_runfiles = []
    drake_prologue = "share/drake/"
    models_internal_runfiles = []
    models_internal_prologue = "share/drake_models/"
    lcmtypes_drake_py_files = []
    lcmtypes_drake_py_prologue = PYTHON_SITE_PACKAGES_RELPATH + "/drake/"
    for dest in ctx.attr.target[InstallInfo].installed_files:
        if dest.startswith(drake_prologue):
            relative_path = dest[len(drake_prologue):]
            if relative_path in known_non_runfiles:
                continue
            if basename(relative_path) in known_non_runfiles_basenames:
                continue
            if any([
                relative_path.startswith(prefix)
                for prefix in known_non_runfiles_dirnames
            ]):
                continue
            drake_runfiles.append(relative_path)
        elif dest.startswith(models_internal_prologue):
            relative_path = dest[len(models_internal_prologue):]
            models_internal_runfiles.append(relative_path)
        elif dest.startswith(lcmtypes_drake_py_prologue):
            relative_path = dest[len(lcmtypes_drake_py_prologue):]
            lcmtypes_drake_py_files.append(relative_path)
    content = {
        "runfiles": {
            "drake": sorted(drake_runfiles),
            "models_internal": sorted(models_internal_runfiles),
        },
        "lcmtypes_drake_py": sorted(lcmtypes_drake_py_files),
        "python_site_packages_relpath": PYTHON_SITE_PACKAGES_RELPATH,
    }
    ctx.actions.write(
        output = ctx.outputs.out,
        content = "MANIFEST = " + struct(**content).to_json(),
        is_executable = False,
    )

generate_installed_files_manifest = rule(
    implementation = _impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [InstallInfo],
            doc = "The install target whose installed paths we'll enumerate.",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "The bzl filename to write out.",
        ),
    },
)
"""Creates a manifest.bzl file containing the list of runfiles installed as
part of the given target.  Currently, only lists Drake's runfiles.
"""
