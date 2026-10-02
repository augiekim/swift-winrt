# Converts resources.rc into a file llvm-rc can compile on non-Windows hosts.
#   - Backslash path separators become forward slashes.
#   - '+' in resource names becomes '.' (llvm-rc doesn't accept '+' in names). The generator
#     maps '.' back to '+' when writing the support files.
#
# Usage: cmake -DINPUT=<resources.rc> -DOUTPUT=<generated .rc> -P generate_non_windows_rc.cmake

if(NOT DEFINED INPUT OR NOT DEFINED OUTPUT)
    message(FATAL_ERROR "INPUT and OUTPUT must be defined")
endif()

file(READ "${INPUT}" content)

string(REPLACE "\\\\" "/" content "${content}")

# Resource names are the first word on a line. Repeat until names with several '+' are fully converted.
set(previous "")
while(NOT content STREQUAL previous)
    set(previous "${content}")
    string(REGEX REPLACE "\n([A-Za-z0-9_.]+)\\+" "\n\\1." content "${content}")
endwhile()

file(WRITE "${OUTPUT}" "${content}")
