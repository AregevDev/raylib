# Set OpenGL_GL_PREFERENCE to new "GLVND" even when legacy library exists and
# cmake is <= 3.10
#
# See https://cmake.org/cmake/help/latest/policy/CMP0072.html for more
# information.
if (POLICY CMP0072)
    cmake_policy(SET CMP0072 NEW)
endif ()

# Split platform libraries from OpenGL
if (${GRAPHICS_BACKEND} MATCHES "rlgl")
    set(GRAPHICS_BACKEND_CPP "GRAPHICS_BACKEND_RLGL")

    if (APPLE)
        # Need to force OpenGL 3.3 on OS X
        # See: https://github.com/raysan5/raylib/issues/341
        set(GRAPHICS "GRAPHICS_API_OPENGL_33")
        find_library(OPENGL_LIBRARY OpenGL)
        set(LIBS_PRIVATE ${OPENGL_LIBRARY})
        link_libraries("${LIBS_PRIVATE}")
        if (NOT CMAKE_SYSTEM STRLESS "Darwin-18.0.0")
            add_definitions(-DGL_SILENCE_DEPRECATION)
            MESSAGE(AUTHOR_WARNING "OpenGL is deprecated starting with macOS 10.14 (Mojave)!")
        endif ()
    elseif (WIN32)
        find_package(OpenGL QUIET)
    else ()
        find_package(OpenGL QUIET)
        if ("${OPENGL_LIBRARIES}" STREQUAL "")
            set(OPENGL_LIBRARIES "GL")
        endif ()
    endif ()
elseif (${GRAPHICS_BACKEND} MATCHES "WGPU")
    set(GRAPHICS_BACKEND_CPP "GRAPHICS_BACKEND_WGPU")
    message(WARNING "The WGPU backend is unstable!")

    find_program(CARGO_DIR cargo)
    if (DEFINED CARGO_DIR)
        message(STATUS "Found cargo at ${CARGO_DIR}")
    else ()
        message(FATAL_ERROR "WGPU Backend requires Rust and Cargo. Make sure they are installed properly.")
    endif ()

    # Doesn't include every platform raylib supports, for now it should be ok.
    if (APPLE)
        set(WGPU_OS_ABI "apple-darwin")
    elseif (WIN32)
        if (MSVC)
            set(WGPU_OS_ABI "pc-windows-msvc")
        elseif ()
            set(WGPU_OS_ABI "pc-windows-msvc")
        endif ()
    elseif (UNIX)
        set(WGPU_OS_ABI "unknown-linux-gnu")
    else ()
        message(FATAL_ERROR "Unsupported WGPU platform!")
    endif ()

    # No cross-compiling for now.
    if (${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "AMD64")
        set(WGPU_ARCH "x86_64")
    elseif (${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "i686")
        set(WGPU_ARCH "i686")
    elseif (${CMAKE_HOST_SYSTEM_PROCESSOR} STREQUAL "aarch64")
        set(WGPU_ARCH "aarch64")
    else ()
        message(FATAL_ERROR "Unsupported WGPU architecture!")
    endif ()

    # Build a release version of wgpu-native, optimized for size.
    set(WGPU_DIR ${CMAKE_CURRENT_SOURCE_DIR}/external/wgpu-native)
    set(WGPU_TARGET_DIR ${CMAKE_CURRENT_BINARY_DIR}/external/wgpu-native-target)
    set(WGPU_TARGET "${WGPU_ARCH}-${WGPU_OS_ABI}")
    set(WGPU_BUILD_COMMAND "rustc" "--release" "--target-dir" ${WGPU_TARGET_DIR} "--target" "${WGPU_TARGET}" "--" "-Copt-level=z")

    add_custom_target(wgpu-native COMMAND ${CARGO_DIR} ${WGPU_BUILD_COMMAND} WORKING_DIRECTORY ${WGPU_DIR} COMMENT "Building wgpu-native")
endif ()

if (${PLATFORM} MATCHES "Desktop")
    set(PLATFORM_CPP "PLATFORM_DESKTOP")

    if (WIN32)
        add_definitions(-D_CRT_SECURE_NO_WARNINGS)
        set(LIBS_PRIVATE ${OPENGL_LIBRARIES} winmm)
    elseif (UNIX)
        find_library(pthread NAMES pthread)

        if ("${CMAKE_SYSTEM_NAME}" MATCHES "(Net|Open)BSD")
            find_library(OSS_LIBRARY ossaudio)
        endif ()

        set(LIBS_PRIVATE m pthread ${OPENGL_LIBRARIES} ${OSS_LIBRARY})
    else ()
        find_library(pthread NAMES pthread)

        set(LIBS_PRIVATE m atomic pthread ${OPENGL_LIBRARIES} ${OSS_LIBRARY})

        if ("${CMAKE_SYSTEM_NAME}" MATCHES "(Net|Open)BSD")
            find_library(OSS_LIBRARY ossaudio)
            set(LIBS_PRIVATE m pthread ${OPENGL_LIBRARIES} ${OSS_LIBRARY})
        endif ()

        if (NOT "${CMAKE_SYSTEM_NAME}" MATCHES "(Net|Open)BSD" AND USE_AUDIO)
            set(LIBS_PRIVATE ${LIBS_PRIVATE} dl)
        endif ()
    endif ()

elseif (${PLATFORM} MATCHES "Web")
    set(PLATFORM_CPP "PLATFORM_WEB")
    if(NOT GRAPHICS)
        set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")
    endif()
    set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")
elseif (${PLATFORM} MATCHES "Android")
    set(PLATFORM_CPP "PLATFORM_ANDROID")
    set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    list(APPEND raylib_sources ${ANDROID_NDK}/sources/android/native_app_glue/android_native_app_glue.c)
    include_directories(${ANDROID_NDK}/sources/android/native_app_glue)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--exclude-libs,libatomic.a -Wl,--build-id -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--warn-shared-textrel -Wl,--fatal-warnings -u ANativeActivity_onCreate -Wl,-undefined,dynamic_lookup")

    find_library(OPENGL_LIBRARY OpenGL)
    set(LIBS_PRIVATE m log android EGL GLESv2 OpenSLES atomic c)
elseif ("${PLATFORM}" MATCHES "DRM")
    set(PLATFORM_CPP "PLATFORM_DRM")
    set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")

    add_definitions(-D_DEFAULT_SOURCE)
    add_definitions(-DEGL_NO_X11)
    add_definitions(-DPLATFORM_DRM)

    find_library(GLESV2 GLESv2)
    find_library(EGL EGL)
    find_library(DRM drm)
    find_library(GBM gbm)

    if (NOT CMAKE_CROSSCOMPILING OR NOT CMAKE_SYSROOT)
        include_directories(/usr/include/libdrm)
    endif ()
    set(LIBS_PRIVATE ${GLESV2} ${EGL} ${DRM} ${GBM} atomic pthread m dl)
elseif ("${PLATFORM}" MATCHES "SDL")
    find_package(SDL2 REQUIRED)
    set(PLATFORM_CPP "PLATFORM_DESKTOP_SDL")
    set(LIBS_PRIVATE SDL2::SDL2)
endif ()

if (NOT ${OPENGL_VERSION} MATCHES "OFF")
    set(SUGGESTED_GRAPHICS "${GRAPHICS}")

    if (${OPENGL_VERSION} MATCHES "4.3")
        set(GRAPHICS "GRAPHICS_API_OPENGL_43")
    elseif (${OPENGL_VERSION} MATCHES "3.3")
        set(GRAPHICS "GRAPHICS_API_OPENGL_33")
    elseif (${OPENGL_VERSION} MATCHES "2.1")
        set(GRAPHICS "GRAPHICS_API_OPENGL_21")
    elseif (${OPENGL_VERSION} MATCHES "1.1")
        set(GRAPHICS "GRAPHICS_API_OPENGL_11")
    elseif (${OPENGL_VERSION} MATCHES "ES 2.0")
        set(GRAPHICS "GRAPHICS_API_OPENGL_ES2")
    elseif (${OPENGL_VERSION} MATCHES "ES 3.0")
        set(GRAPHICS "GRAPHICS_API_OPENGL_ES3")
    endif ()
    if (NOT "${SUGGESTED_GRAPHICS}" STREQUAL "" AND NOT "${SUGGESTED_GRAPHICS}" STREQUAL "${GRAPHICS}")
        message(WARNING "You are overriding the suggested GRAPHICS=${SUGGESTED_GRAPHICS} with ${GRAPHICS}! This may fail.")
    endif ()
endif ()

if (${GRAPHICS_BACKEND} MATCHES "WGPU")
    if (WIN32)
        set(LIBS_PRIVATE ${LIBS_PRIVATE} d3dcompiler ws2_32 userenv bcrypt ntdll opengl32)
    elseif (APPLE)
        set(LIBS_PRIVATE ${LIBS_PRIVATE} -framework CoreFoundation -framework QuartzCore -framework Metal)
    endif ()
    
    set(LIBS_PRIVATE ${LIBS_PRIVATE} wgpu_native)
endif ()

if (NOT GRAPHICS)
    set(GRAPHICS "GRAPHICS_API_OPENGL_33")
endif ()

set(LIBS_PRIVATE ${LIBS_PRIVATE} ${OPENAL_LIBRARY})

if (${PLATFORM} MATCHES "Desktop")
    set(LIBS_PRIVATE ${LIBS_PRIVATE} glfw)
endif ()
