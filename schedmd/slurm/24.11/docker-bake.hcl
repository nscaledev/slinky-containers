// SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
// SPDX-License-Identifier: Apache-2.0

################################################################################

variable "DOCKER_BAKE_REGISTRY" {
  default = "ghcr.io/nscaledev"
}

variable "DOCKER_BAKE_SUFFIX" {}

slurm_version = "24.11.5"

variable "LMOD_VERSION" {
  default = "8.7.59"
}

variable "ROCM_VERSION" {
  default = "6.3.4"
}

variable "PYXIS_VERSION" {
  default = "0.20.0"
}

function "slurm_semantic_version" {
  params = [version]
  result = regex("^(?<major>[0-9]+)\\.(?<minor>[0-9]+)\\.(?<patch>[0-9]+)(?:-(?<rev>.+))?$", "${version}")
}

function "slurm_version" {
  params = [version]
  result = (
    length(regexall("^(?<major>[0-9]+)\\.(?<minor>[0-9]+)\\.(?<patch>[0-9]+)(?:-(?<rev>.+))?$", "${version}")) > 0
      ? "${format("%s.%s", "${slurm_semantic_version("${version}")["major"]}", "${slurm_semantic_version("${version}")["minor"]}")}"
      : "${version}"
  )
}

function "tag_timestamp" {
params = []
  result = formatdate("YYMMDDhhmm", timestamp())
}

function "format_tag" {
  params = [registry, stage, version, flavor, suffix, timestamp]
  result = format("%s:%s", join("/slinky-", compact([registry, stage])), join("-", compact([version, flavor, suffix, timestamp])))
}

################################################################################

target "_slurm" {
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.authors" = "Ncale"
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/documentation.html"
    "org.opencontainers.image.license" = "GPL-2.0-or-later WITH openssl-exception"
    "org.opencontainers.image.vendor" = "Nscale"
    "org.opencontainers.image.version" = "${slurm_version}"
    "org.opencontainers.image.source" = "https://github.com/nscaledev/slinky-containers"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "vendor" = "Nscale"
    "version" = "${slurm_version}"
    "release" = "https://github.com/nscaledev/slinky-containers"
  }
}

target "_slurmctld" {
  inherits = ["_slurm"]
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.title" = "Slurm Control Plane"
    "org.opencontainers.image.description" = "slurmctld - The central management daemon of Slurm"
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/slurmctld.html"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "name" = "Slurm Control Plane"
    "summary" = "slurmctld - The central management daemon of Slurm"
    "description" = "slurmctld - The central management daemon of Slurm"
  }
}

target "_slurmd" {
  inherits = ["_slurm"]
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.title" = "Slurm Worker Agent"
    "org.opencontainers.image.description" = "slurmd - The compute node daemon for Slurm"
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/slurmd.html"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "name" = "Slurm Worker Agent"
    "summary" = "slurmd - The compute node daemon for Slurm"
    "description" = "slurmd - The compute node daemon for Slurm"
  }
}

target "_slurmdbd" {
  inherits = ["_slurm"]
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.title" = "Slurm Database Agent"
    "org.opencontainers.image.description" = "slurmdbd - Slurm Database Daemon"
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/slurmdbd.html"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "name" = "Slurm Database Agent"
    "summary" = "slurmdbd - Slurm Database Daemon"
    "description" = "slurmdbd - Slurm Database Daemon"
  }
}

target "_slurmrestd" {
  inherits = ["_slurm"]
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.title" = "Slurm REST API Agent"
    "org.opencontainers.image.description" = "slurmrestd - Interface to Slurm via REST API"
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/slurmrestd.html"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "name" = "Slurm REST API Agent"
    "summary" = "slurmrestd - Interface to Slurm via REST API"
    "description" = "slurmrestd - Interface to Slurm via REST API"
  }
}

target "_sackd" {
  inherits = ["_slurm"]
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.title" = "Slurm Auth/Cred Server"
    "org.opencontainers.image.description" = "sackd - Slurm Auth and Cred Kiosk Daemon"
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/sackd.html"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "name" = "Slurm Auth/Cred Server"
    "summary" = "sackd - Slurm Auth and Cred Kiosk Daemon"
    "description" = "sackd - Slurm Auth and Cred Kiosk Daemon"
  }
}

target "_login" {
  inherits = ["_slurm"]
  labels = {
    # Ref: https://github.com/opencontainers/image-spec/blob/v1.0/annotations.md
    "org.opencontainers.image.title" = "Slurm Login Container"
    "org.opencontainers.image.description" = "An authenticated environment to submit Slurm workload from."
    "org.opencontainers.image.documentation" = "https://slurm.schedmd.com/quickstart_admin.html#login"
    # Ref: https://docs.redhat.com/en/documentation/red_hat_software_certification/2025/html/red_hat_openshift_software_certification_policy_guide/assembly-requirements-for-container-images_openshift-sw-cert-policy-introduction#con-image-metadata-requirements_openshift-sw-cert-policy-container-images
    "name" = "Slurm Login Container"
    "summary" = "An authenticated environment to submit Slurm workload from."
    "description" = "An authenticated environment to submit Slurm workload from."
  }
}

################################################################################

group "default" {
  targets = [
    "rockylinux9",
    "ubuntu2404",
  ]
}

group "core" {
  targets = [
    "rockylinux9-core",
    "ubuntu2404-core",
  ]
}

group "extras" {
  targets = [
    "rockylinux9-extras",
    "ubuntu2404-extras",
  ]
}

################################################################################

group "rockylinux9" {
  targets = [
    "rockylinux9-core",
    "rockylinux9-extras",
  ]
}

group "rockylinux9-core" {
  targets = [
    "slurmctld_rockylinux9",
    "slurmd_rockylinux9",
    "slurmdbd_rockylinux9",
    "slurmrestd_rockylinux9",
    "sackd_rockylinux9",
    "login_rockylinux9",
  ]
}

target "_rockylinux9" {
  context = "rockylinux9"
  args = {
    SLURM_VERSION = "${slurm_version}"
    ROCM_VERSION = "${ROCM_VERSION}"
    LMOD_VERSION = "${LMOD_VERSION}"
    PYXIS_VERSION = "${PYXIS_VERSION}"
  }
}

target "slurmctld_rockylinux9" {
  inherits = ["_slurmctld", "_rockylinux9"]
  target = "slurmctld"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "slurmd_rockylinux9" {
  inherits = ["_slurmd", "_rockylinux9"]
  target = "slurmd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "slurmdbd_rockylinux9" {
  inherits = ["_slurmdbd", "_rockylinux9"]
  target = "slurmdbd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "slurmrestd_rockylinux9" {
  inherits = ["_slurmrestd", "_rockylinux9"]
  target = "slurmrestd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "sackd_rockylinux9" {
  inherits = ["_sackd", "_rockylinux9"]
  target = "sackd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "login_rockylinux9" {
  inherits = ["_login", "_rockylinux9"]
  target = "login"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "login", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "login", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

################################################################################

group "rockylinux9-extras" {
  targets = [
    "slurmd_pyxis_rockylinux9",
    "login_pyxis_rockylinux9",
  ]
}

target "slurmd_pyxis_rockylinux9" {
  inherits = ["_slurmd", "_rockylinux9"]
  dockerfile = "Dockerfile.pyxis"
  target = "slurmd-pyxis"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd-pyxis", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd-pyxis", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
  contexts = {
    "ghcr.io/slinkyproject/slurmd:24.11-rockylinux9" = "target:slurmd_rockylinux9"
  }
}

target "login_pyxis_rockylinux9" {
  inherits = ["_login", "_rockylinux9"]
  dockerfile = "Dockerfile.pyxis"
  target = "login-pyxis"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "login-pyxis", "${slurm_version("${slurm_version}")}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "login-pyxis", "${slurm_version}", "rockylinux9", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
  contexts = {
    "ghcr.io/slinkyproject/slurmd:24.11-rockylinux9" = "target:slurmd_rockylinux9"
    "ghcr.io/slinkyproject/login:24.11-rockylinux9" = "target:login_rockylinux9"
  }
}

################################################################################

group "ubuntu2404" {
  targets = [
    "ubuntu2404-core",
    "ubuntu2404-extras",
  ]
}

group "ubuntu2404-core" {
  targets = [
    "slurmctld_ubuntu2404",
    "slurmd_ubuntu2404",
    "slurmdbd_ubuntu2404",
    "slurmrestd_ubuntu2404",
    "sackd_ubuntu2404",
    "login_ubuntu2404",
  ]
}

target "_ubuntu2404" {
  context = "ubuntu24.04"
  args = {
    SLURM_VERSION = "${slurm_version}"
    ROCM_VERSION = "${ROCM_VERSION}"
    LMOD_VERSION = "${LMOD_VERSION}"
    PYXIS_VERSION = "${PYXIS_VERSION}"
  }
}

target "slurmctld_ubuntu2404" {
  inherits = ["_slurmctld", "_ubuntu2404"]
  target = "slurmctld"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmctld", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "slurmd_ubuntu2404" {
  inherits = ["_slurmd", "_ubuntu2404"]
  target = "slurmd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd-base", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd-base", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "slurmdbd_ubuntu2404" {
  inherits = ["_slurmdbd", "_ubuntu2404"]
  target = "slurmdbd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmdbd", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "slurmrestd_ubuntu2404" {
  inherits = ["_slurmrestd", "_ubuntu2404"]
  target = "slurmrestd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmrestd", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "sackd_ubuntu2404" {
  inherits = ["_sackd", "_ubuntu2404"]
  target = "sackd"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "sackd", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

target "login_ubuntu2404" {
  inherits = ["_login", "_ubuntu2404"]
  target = "login"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "login-base", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "login-base", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
}

################################################################################

group "ubuntu2404-extras" {
  targets = [
    "slurmd_pyxis_ubuntu2404",
    "login_pyxis_ubuntu2404",
  ]
}

target "slurmd_pyxis_ubuntu2404" {
  inherits = ["_slurmd", "_ubuntu2404"]
  dockerfile = "Dockerfile.pyxis"
  target = "slurmd-pyxis"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "slurmd", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
  contexts = {
    "ghcr.io/slinkyproject/slurmd:24.11-ubuntu24.04" = "target:slurmd_ubuntu2404"
  }
}

target "login_pyxis_ubuntu2404" {
  inherits = ["_login", "_ubuntu2404"]
  dockerfile = "Dockerfile.pyxis"
  target = "login-pyxis"
  tags = [
    format_tag("${DOCKER_BAKE_REGISTRY}", "login", "${slurm_version("${slurm_version}")}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
    format_tag("${DOCKER_BAKE_REGISTRY}", "login", "${slurm_version}", "ubuntu24.04", "${DOCKER_BAKE_SUFFIX}", "${tag_timestamp()}"),
  ]
  contexts = {
    "ghcr.io/slinkyproject/slurmd:24.11-ubuntu24.04" = "target:slurmd_ubuntu2404"
    "ghcr.io/slinkyproject/login:24.11-ubuntu24.04" = "target:login_ubuntu2404"
  }
}
