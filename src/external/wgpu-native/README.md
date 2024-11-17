# wgpu-native (Modified for raylib)
[![Matrix](https://img.shields.io/badge/Matrix-%23wgpu%3Amatrix.org-blueviolet.svg)](https://matrix.to/#/#wgpu:matrix.org)
[![Build Status](https://github.com/gfx-rs/wgpu-native/workflows/CI/badge.svg)](https://github.com/gfx-rs/wgpu-native/actions)

This directory contains a modified version of `wgpu-native`. The original version can be found at https://github.com/gfx-rs/wgpu-native. **No code / `cargo` changes were made.**

### Changes
#### `wgpu-native`
- Removed `.gitmodules` and bundled `wgpu-headers`.
- Removed examples directory
- Removed `.gitignore`. Rust build files / directories were added to the main `.gitignore` file.
- Removed CI scripts.

#### `webgpu-headers`
- Removed CI scripts.
- Removed `.gitattributes`
