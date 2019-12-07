if (${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    message(FATAL_ERROR "Prevented in-tree build. Please create a build directory outside of the source code and call cmake from there")
endif ()

##! Minimum version of the CMake.
cmake_minimum_required(VERSION 3.14)

##! C++ Standard needed by the SDK is 17
set(CMAKE_CXX_STANDARD 17)

##! Our Project title, here atomic-dex-desktop.
project(atomic-dex-desktop DESCRIPTION "An awesome atomic-dex-desktop" LANGUAGES CXX VERSION 1.0.0)

if (WIN32)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Override option" FORCE)
endif()

##! The SDK need's clang as main compiler.
if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    if (NOT "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
        message(FATAL_ERROR "Only Clang is supported (minimum LLVM 8.0)")
    endif ()
endif ()

##! We will let know the SDK if our on Linux
if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(LINUX TRUE)
endif ()

##! Options
option(ENABLE_CODE_RELOAD_UNIX "Enable hot-code reloading on unix" OFF)

##! We include the module from CMake for fetching dependencies
include(FetchContent)

##! We declare information about the dependance that we want to fetch.
FetchContent_Declare(
        antara-gaming-sdk
        URL https://github.com/KomodoPlatform/antara-gaming-sdk/archive/master.zip

)

if (UNIX)
    FetchContent_Declare(
            jetlive
            URL https://github.com/ddovod/jet-live/archive/macos_10.15.zip
    )
endif ()

FetchContent_Declare(
        iconfontcppheaders
        URL https://github.com/juliettef/IconFontCppHeaders/archive/master.zip
)

##! We set extras modules from the SDK that we want to use, here we will use the SFML module.
set(USE_SFML_ANTARA_WRAPPER ON)
set(USE_IMGUI_ANTARA_WRAPPER ON)
set(ENABLE_BLOCKCHAIN_MODULES ON)

##! We fetch our dependence
if (APPLE)
    FetchContent_Declare(mm2
            URL http://195.201.0.6/mm2/mm2-latest-Darwin.zip)
elseif (LINUX)
    FetchContent_Declare(mm2
            URL http://195.201.0.6/mm2/mm2-latest-Linux.zip)
else ()
    FetchContent_Declare(mm2
            URL http://195.201.0.6/mm2/mm2-latest-Windows_NT.zip)
endif ()

FetchContent_Declare(jl777-coins
        URL https://github.com/jl777/coins/archive/master.zip)

FetchContent_MakeAvailable(mm2 jl777-coins iconfontcppheaders)
##! Configure our needs.
if (UNIX)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/coins.json COPYONLY)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/coins COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/mm2 ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/mm2 COPYONLY)
    file(COPY ${jl777-coins_SOURCE_DIR}/electrums DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/)
    file(COPY ${jl777-coins_SOURCE_DIR}/icons DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/assets/textures/)
else ()
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/coins.json COPYONLY)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/coins COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/mm2.exe ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/mm2.exe COPYONLY)
    file(COPY ${jl777-coins_SOURCE_DIR}/electrums DESTINATION ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/)
    file(COPY ${jl777-coins_SOURCE_DIR}/icons DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/assets/textures/)
endif ()

#FetchContent_MakeAvailable(antara-gaming-sdk)
FetchContent_GetProperties(antara-gaming-sdk)
if (NOT antara-gaming-sdk_POPULATED)
    FetchContent_Populate(antara-gaming-sdk)
    add_subdirectory(${antara-gaming-sdk_SOURCE_DIR} ${antara-gaming-sdk_BINARY_DIR} EXCLUDE_FROM_ALL)
endif ()

##! Calling this macros provided by the sdk will if you are on Apple init the environment for this OS (std::filesystem).
init_antara_env()

##! Get basis assets (default fonts, etc)
get_resources_basics_assets(${CMAKE_CURRENT_SOURCE_DIR})

##! Osx bundle icon
set(ICON)
configure_icon_osx(data/osx/kmd_logo.icns ICON kmd_logo.icns)

##! We create the executable with the project name
add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${ICON}
        atomic.dex.desktop.cpp
        src/atomic.dex.app.cpp
        src/atomic.dex.gui.cpp
        src/atomic.dex.mm2.cpp
        src/atomic.dex.mm2.api.cpp
        src/atomic.dex.gui.style.cpp
        src/atomic.dex.gui.widgets.cpp
        src/atomic.dex.coins.config.cpp)

if (UNIX AND ENABLE_CODE_RELOAD_UNIX)
    target_compile_definitions(${PROJECT_NAME} PUBLIC -DENABLE_CODE_RELOAD_UNIX)
    FetchContent_GetProperties(jetlive)
    if (NOT jetlive_POPULATED)
        FetchContent_Populate(jetlive)
        include(${jetlive_SOURCE_DIR}/cmake/jet_live_setup.cmake) # setup needed compiler and linker flags, include this file in your root CMakeLists.txt
        set(JET_LIVE_BUILD_EXAMPLE OFF CACHE BOOL "Override option" FORCE)
        set(JET_LIVE_SHARED ON CACHE BOOL "Override option" FORCE)
        add_subdirectory(${jetlive_SOURCE_DIR} ${jetlive_BINARY_DIR} EXCLUDE_FROM_ALL)
        target_link_libraries(${PROJECT_NAME} PUBLIC jet-live)
    endif ()
endif ()

target_include_directories(${PROJECT_NAME} PUBLIC src ${iconfontcppheaders_SOURCE_DIR})

##! Setting output directory
set_target_properties(${PROJECT_NAME}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/"
        )

magic_game_app_image_generation("${CMAKE_CURRENT_SOURCE_DIR}/data/linux"
        "org.antara.gaming.sfml.wolf3d.desktop"
        "org.antara.gaming.sfml.wolf3d.appdata.xml"
        "komodo_icon.png"
        atomic-dex-desktop
        AntaraAtomicDexAppDir
        ${CMAKE_CURRENT_SOURCE_DIR}/assets
        )

##! We link the SDK modules that we want to use to our executable
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Override option" FORCE)

target_link_libraries(${PROJECT_NAME} PUBLIC antara::world
        antara::sfml_resources
        antara::sfml_extras
        antara::sfml_graphic
        antara::sfml_input
        reproc++
        joboccara::pipes
        nlohmann_json::nlohmann_json
        antara::http_client)

##! Move assets
if (WIN32)
    file(COPY assets DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    get_target_property(target_runtime_directory ${PROJECT_NAME} RUNTIME_OUTPUT_DIRECTORY)
    ADD_CUSTOM_COMMAND(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory "${SFML_SOURCE_DIR}/extlibs/bin/x64" "${target_runtime_directory}"
            COMMENT "copying dlls …"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
            )
endif ()

if (APPLE)
    ADD_CUSTOM_COMMAND(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory "${SFML_SOURCE_DIR}/extlibs/libs-osx/Frameworks" "${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.app/Contents/Frameworks"
            COMMENT "copying frameworks …"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
            )
    file(COPY assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.app/Contents/Resources)
    include(data/osx/sfml_atomicdex_install.cmake)
endif ()


target_enable_tsan(${PROJECT_NAME})