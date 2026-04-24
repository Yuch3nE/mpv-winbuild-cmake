set(version "v3.31.6")

set(_externalproject_root "${CMAKE_CURRENT_BINARY_DIR}/cmake/Modules")
set(_externalproject_dir "${_externalproject_root}/ExternalProject")
set(_externalproject_setup_done "${_externalproject_root}/setup_done")
set(_externalproject_zip "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CMake-${version}-Modules-ExternalProject.zip")
set(_externalproject_patch "${CMAKE_CURRENT_SOURCE_DIR}/packages/cmake-0001-ExternalProject-changes.patch")
set(_externalproject_main_module "${_externalproject_root}/ExternalProject.cmake")

file(MAKE_DIRECTORY ${_externalproject_dir})

if(NOT EXISTS "${_externalproject_setup_done}")
    find_program(PATCH_EXECUTABLE patch NO_CACHE)
    if(NOT PATCH_EXECUTABLE)
        message(FATAL_ERROR "The 'patch' executable is required to bootstrap ExternalProject.")
    endif()

    file(ARCHIVE_EXTRACT INPUT ${_externalproject_zip} DESTINATION ${_externalproject_dir})
    file(DOWNLOAD
        https://github.com/Kitware/CMake/raw/refs/tags/${version}/Modules/ExternalProject.cmake
        ${_externalproject_main_module}
        STATUS _download_status
        SHOW_PROGRESS
    )
    list(GET _download_status 0 _download_code)
    list(GET _download_status 1 _download_message)
    if(NOT _download_code EQUAL 0)
        message(FATAL_ERROR "Failed to download ExternalProject.cmake: ${_download_message}")
    endif()

    execute_process(
        COMMAND ${PATCH_EXECUTABLE} --dry-run --forward -p1 -i ${_externalproject_patch}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake
        RESULT_VARIABLE _patch_dry_run_result
    )

    if(_patch_dry_run_result EQUAL 0)
        execute_process(
            COMMAND ${PATCH_EXECUTABLE} --forward -p1 -i ${_externalproject_patch}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake
            RESULT_VARIABLE _patch_result
        )
        if(NOT _patch_result EQUAL 0)
            message(FATAL_ERROR "Failed to apply ExternalProject patch.")
        endif()
    else()
        execute_process(
            COMMAND ${PATCH_EXECUTABLE} --dry-run --forward -R -p1 -i ${_externalproject_patch}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cmake
            RESULT_VARIABLE _patch_reverse_dry_run_result
        )
        if(NOT _patch_reverse_dry_run_result EQUAL 0)
            message(FATAL_ERROR "ExternalProject patch is neither applicable nor already applied.")
        endif()
    endif()

    file(TOUCH ${_externalproject_setup_done})
endif()

include(${_externalproject_main_module})
