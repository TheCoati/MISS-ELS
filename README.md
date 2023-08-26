# MIX-EUP

Heavily modified ELS resource based of [MISS-ELS]() for the [MIX RP](https://servers.fivem.net/servers/detail/g5xpkm) FiveM server. 

- Added OneSync infinity support.
- Modified to mimic real life Dutch emergency lighting systems.
- Added "Modiforce" interface to control lighting.

## Table of Contents

- [Installation](#installation)
- [VCF Format](#vcf-format)
- [Disclaimer](#disclaimer)

## Installation

- Download the latest version from GitHub as zip.
- Extract the zip into your FiveM `resources` folder.
- Rename the folder to `mix-els`.
- Configure the resource to your likings in the [config.lua](config.lua).
- Put your ELS files into the [xmlFiles](xmlFiles) folder (see [VCF Format](#vcf-format))
- Start the resource using `refresh` and `start mix-els`.

## VCF Format

This resource is fully compatible with the [MISS-ELS](https://github.com/matsn0w/MISS-ELS) configurator https://matsn0w.github.io/MISS-ELS/ \
The "default" ELS configurations file will not work this resource.

## Disclaimer

This resource has been hardcoded modified to mimic real life Dutch emergency lighting systems. \
Adding this resource to your server without any modification might **not** work as expected. \
Please use this only as inspiration or boilerplate.