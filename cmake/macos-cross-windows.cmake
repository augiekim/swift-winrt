# Toolchain file for cross-compiling swiftwinrt.exe (Windows x64) from macOS.
#
# Requirements:
#   - LLVM with clang-cl, llvm-rc, llvm-mt, llvm-lib (brew install llvm)
#   - lld-link (brew install lld)
#   - Windows SDK and CRT files from xwin (brew install xwin && xwin --accept-license --temp splat --output ~/.xwin)
#
# Tool lookup order: $LLVM_ROOT/bin, Homebrew's llvm and lld prefixes, then PATH.
# Homebrew is searched before PATH because Xcode's clang on PATH doesn't ship the Windows tools.
# The xwin location defaults to ~/.xwin and can be overridden with $XWIN_DIR.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)

set(_target x86_64-pc-windows-msvc)
set(CMAKE_C_COMPILER_TARGET ${_target})
set(CMAKE_CXX_COMPILER_TARGET ${_target})

# xwin doesn't include debug CRT libraries by default, so compiler checks must link against release ones
set(CMAKE_TRY_COMPILE_CONFIGURATION Release)

# This file is re-read for every compiler check, so remember the Homebrew lookup in the environment
# (inherited by the checks) instead of running brew each time.
if(NOT DEFINED ENV{_SWIFTWINRT_LLVM_HINTS})
    set(_hints "")
    if(DEFINED ENV{LLVM_ROOT})
        list(APPEND _hints "$ENV{LLVM_ROOT}/bin")
    endif()
    find_program(_brew brew)
    if(_brew)
        foreach(_formula llvm lld)
            execute_process(COMMAND ${_brew} --prefix ${_formula}
                OUTPUT_VARIABLE _prefix OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
            if(_prefix)
                list(APPEND _hints "${_prefix}/bin")
            endif()
        endforeach()
    endif()
    set(ENV{_SWIFTWINRT_LLVM_HINTS} "${_hints}")
endif()
set(_hints "$ENV{_SWIFTWINRT_LLVM_HINTS}")

find_program(CMAKE_C_COMPILER clang-cl HINTS ${_hints} REQUIRED)
set(CMAKE_CXX_COMPILER ${CMAKE_C_COMPILER})
find_program(CMAKE_LINKER lld-link HINTS ${_hints} REQUIRED)
find_program(CMAKE_RC_COMPILER llvm-rc HINTS ${_hints} REQUIRED)
find_program(CMAKE_MT llvm-mt HINTS ${_hints} REQUIRED)
find_program(CMAKE_AR llvm-lib HINTS ${_hints} REQUIRED)

if(DEFINED ENV{XWIN_DIR})
    set(_xwin "$ENV{XWIN_DIR}")
else()
    set(_xwin "$ENV{HOME}/.xwin")
endif()
if(NOT EXISTS "${_xwin}/sdk/include/um/Windows.h")
    message(FATAL_ERROR "Windows SDK files not found in ${_xwin}. Run:\n"
        "  brew install xwin && xwin --accept-license --temp splat --output ${_xwin}\n"
        "or set XWIN_DIR to an existing xwin splat directory.")
endif()

set(_includes "")
foreach(_dir crt/include sdk/include/ucrt sdk/include/um sdk/include/shared sdk/include/winrt)
    string(APPEND _includes " -imsvc ${_xwin}/${_dir}")
endforeach()
set(CMAKE_C_FLAGS_INIT "${_includes}")
set(CMAKE_CXX_FLAGS_INIT "${_includes}")
set(CMAKE_RC_FLAGS_INIT "-I ${_xwin}/sdk/include/um -I ${_xwin}/sdk/include/shared")

set(_libpaths "")
foreach(_dir crt/lib/x86_64 sdk/lib/um/x86_64 sdk/lib/ucrt/x86_64)
    string(APPEND _libpaths " /libpath:${_xwin}/${_dir}")
endforeach()
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_libpaths}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_libpaths}")
