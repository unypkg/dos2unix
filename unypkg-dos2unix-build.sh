#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2086,SC2016

set -xv

######################################################################################################################
### Setup Build System and GitHub

apt install -y po4a dos2unix zip

wget -qO- uny.nu/pkg | bash -s buildsys

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="dos2unix"
pkggit="https://git.code.sf.net/p/dos2unix/dos2unix refs/tags/dos2unix-*"
gitdepth="--depth=1"

### Get version info from git remote
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "dos2unix-[0-9.]*$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "dos2unix-[0-9.]*" | sed "s|dos2unix-||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

check_for_repo_and_create
git_clone_source_repo

cd dos2unix || exit
make dist
cd /uny/sources || exit
rm -rvf d2u752 d2u752.zip dos2unix dos2unix-*.tar.gz
mv -v dos2unix-* dos2unix

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
unyc <<"UNYEOF"
set -xv
source /uny/git/unypkg/fn

pkgname="dos2unix"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths_temp

####################################################
### Start of individual build script

unset LD_RUN_PATH

cat Makefile | sed "s|prefix.*=.*/usr|prefix=|g" -i Makefile

make -j"$(nproc)"
make -j"$(nproc)" check

mkdir -pv /uny/pkg/"$pkgname"/"$pkgver"
make DESTDIR=/uny/pkg/"$pkgname"/"$pkgver" install

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
