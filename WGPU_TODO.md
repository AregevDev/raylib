# WGPU Backend TODO List

This document should be removed once we merge into `raylib`.

### Project Setup
- [x] Add the `wgpu-native` source code to the `external` folder.
- [ ] Add CMake integration and logic to `CMake` to build `wgpu-native`.
- [ ] Add the necessary build flags / preprocessor flags to distinguish the `wgpu` backend from the already-existing `rlgl` backend.
- [ ] Add CI
  - [ ] Write and test the GitHub workflows for the `wgpu` backend.
  - [ ] Make sure CI passes on all platforms, in all cases.

### Clearing the Background
- [ ] Modify `CreateWindow` to create the required WGPU primitives.
- [ ] Create a surface on all platforms using `GLFW`'s native functions.
- [ ] Implement `BeginDrawing` `ClearBackground` and `EndDrawing`.
- [ ] Test on all platforms

### Unresolved / Gotchas
#### Project Setup
- [ ] Should we write a script that automates the bundling of `wgpu-native`?
- [ ] `wgpu-native` uses git submodules for its dependencies. `raylib` doesn't. For now, we bundle a modified version of `wgpu-native` in `raylib`'s repository.
- [ ] The `wgpu-native` library is huge (~250MB) Need to optimize for size when building the library.
- [ ] Should we build the library from source? `wgpu-native` provides binary release on GitHub as well. Should we support both options?

#### API
TBD.
