# <img src="https://raw.githubusercontent.com/SpamTagger/SpamTagger/refs/heads/main/www/user/templates/default/images/st_logo.svg" alt="SpamTagger Logo" style="height:2em; vertical-align:middle;"> SpamTagger

SpamTagger is a continuation of the MailCleaner® anti spam gateway.

## 🚧 Under Construction 🚧

Development of a first release of SpamTagger is ongoing and the SpamTagger repository is no longer compatible with existing MailCleaner® systems which are based on Debian Jessie.

There are currently no pre-built VMs to download for SpamTagger. [Containers](https://github.com/SpamTagger/SpamTagger-Bootc/pkgs/container/spamtagger-bootc) and VM images can be built using the [SpamTagger-Bootc repository](https://github.com/SpamTagger/SpamTagger-Bootc). However, these images do not currently produce a working mail gateway.

Please stay tuned for more information and feel free to discuss development in the relevant GitHub Issues or Discussions tabs.

## 👨‍💻 Development 👩‍💻

In the effort to get out a new release development is ongoing across a few different repositories. A minimum viable product for each of these is required before SpamTagger will be fully functional:

- [ ] [This repository](https://github.com/SpamTagger/SpamTagger) contains the SpamTagger application code. Work is ongoing to bring the codebase up to date to support the latest language and framework versions. Application services are also being modernized to run with more appropriate permissions, access an other considerations. See the [issues page](https://github.com/SpamTagger/SpamTagger/issues) for problems that need to be resolved.
- [ ] The [SpamTagger-Bootc](https://github.com/SpamTagger/SpamTagger-Bootc) repository is responsible for building SpamTagger images in various formats. This is a significant divergence from how MailCleaner® images were built as discussed [here](https://github.com/orgs/SpamTagger/discussions/3). It is capable of building container images, VM images and ISO installers, however work is ongoing to move as much installation code to the main SpamTagger repository instead and to cleanly run the installation and test steps from there.
- [x] The [st-exim](https://github.com/SpamTagger/st-exim) repository builds custom versions of the [exim](https://github.com/exim/exim) MTA for SpamTagger appliances, since distribution provided versions are missing several necessary features. Packages are now built successfully each time that a new tag is created and the packages get uploaded to the GitHub Releases page.
- [ ] The [st-mailscanner](https://github.com/SpamTagger/v5) repository builds a custom version of the [mailscanner](https://www.mailscanner.info) email filter, since SpamTagger introduces custom functionality which is not currently pluggable. Changes from the version in MailCleaner need to be ported to the lasted version and then the package needs to borrow the same build process from `st-exim`.
- [x] The [debs](https://github.com/SpamTagger/debs) repository fetches the various custom Debian packages used by SpamTagger and assembled them into a compatible APT package repository, including signing the repository, hosting it via GitHub Pages and creating an HTML index.
- [ ] The [python-mailcleaner-library](https://github.com/SpamTagger/python-mailcleaner-library) provides some internal API features, mostly for [Fail2Ban](https://github.com/fail2ban/fail2ban) integration. This should not require any significant modification for a minimal release. However it is eventually desired to remove this and replace it with a built-in Perl-based API since this is the only Python code across all SpamTagger projects.
