# Source roots to relativize filenames against
target_compile_definitions(stacktrace PRIVATE
    SOURCE_ROOT1=${CMAKE_SOURCE_DIR} SOURCE_ROOT2=${CMAKE_BINARY_DIR})
# CPM stores source path as absoule path. If it is not, CPM has not been loaded
if (DEFINED CPM_SOURCE_CACHE)
    cmake_path(IS_ABSOLUTE CPM_SOURCE_CACHE is_absolute)
    if(is_absolute)
        target_compile_definitions(stacktrace PRIVATE
            SOURCE_ROOT3=${CPM_SOURCE_CACHE})
    endif()
endif()

# Link against dependent libraries
if(WIN32)
    target_link_libraries(stacktrace PRIVATE imagehlp)
else()
    # Maybe we should add some option to control this for the user..?

    # find_path(LIBDWARF_INCLUDE_DIR NAMES "libdwarf.h" PATH_SUFFIXES libdwarf)
	# find_path(LIBELF_INCLUDE_DIR NAMES "libelf.h")
	# find_path(LIBDL_INCLUDE_DIR NAMES "dlfcn.h")
	# find_library(LIBDWARF_LIBRARY dwarf)
	# find_library(LIBELF_LIBRARY elf)
	# find_library(LIBDL_LIBRARY dl)
	# set(LIBDWARF_INCLUDE_DIRS ${LIBDWARF_INCLUDE_DIR} ${LIBELF_INCLUDE_DIR} ${LIBDL_INCLUDE_DIR})
	# set(LIBDWARF_LIBRARIES ${LIBDWARF_LIBRARY} ${LIBELF_LIBRARY} ${LIBDL_LIBRARY})

    # set(libs ${LIBDWARF_LIBRARIES})
    # set(dirs ${LIBDWARF_INCLUDE_DIRS})
    # set(libs dw)
    # set(dirs "")
    # target_compile_definitions(stacktrace PRIVATE BACKWARD_HAS_DWARF=1)

    # target_link_libraries(stacktrace PRIVATE ${libs})
    # target_include_directories(stacktrace PRIVATE ${dirs})
    # target_compile_definitions(stacktrace PRIVATE
        # ENABLE_STACKTRACE=1)
    # target_link_libraries(stacktrace dw)
    # target_compile_definitions(stacktrace PRIVATE BACKWARD_HAS_DW=1)
    find_library(BFD bfd)
    if(BFD)
        target_compile_definitions(stacktrace PRIVATE BACKWARD_HAS_BFD=1)
        target_link_libraries(stacktrace PRIVATE ${BFD} dl)
    else()
        message(WARNING "libbfd not found. Stacktrace generation will be disabled!")
    endif()
endif()