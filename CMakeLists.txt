cmake_minimum_required(VERSION 3.5)

project(atomicdex-desktop LANGUAGES CXX VERSION 0.3.0)


option(DISABLE_GEOBLOCKING "Enable to disable geoblocking (for dev purpose)" OFF)
set(FETCHCONTENT_QUIET OFF CACHE BOOL "Override option" FORCE)


set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POLICY_WARNING_CMP0100 OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if (EXISTS ${CMAKE_BINARY_DIR}/conan_paths.cmake)
    set(CONAN_ENABLED ON)
    message(STATUS "Conan package manager enabled")
    include(${CMAKE_BINARY_DIR}/conan_paths.cmake)
else ()
    message(STATUS "VCPKG package manager enabled")
endif ()

##! Antara
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
include(antara)
##! Calling this macros provided by the sdk will if you are on Apple init the environment for this OS (std::filesystem).
init_antara_env()


##! We include the module from CMake for fetching dependencies
include(FetchContent)

if (${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    set(LINUX TRUE)
endif ()

if (UNIX AND NOT APPLE)
    message("Forcing stdlib C++")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++ -lc++abi")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif ()

##! We fetch our dependencies
if (APPLE)
    FetchContent_Declare(mm2
            URL https://github.com/KomodoPlatform/atomicDEX-API/releases/download/beta-2.0.2422/mm2-31d1803b0-Darwin-Release.zip)
elseif (UNIX AND NOT APPLE)
    FetchContent_Declare(mm2
            URL https://github.com/KomodoPlatform/atomicDEX-API/releases/download/beta-2.0.2422/mm2-31d1803b0-Linux-Release.zip)
else ()
    FetchContent_Declare(mm2
            URL https://github.com/KomodoPlatform/atomicDEX-API/releases/download/beta-2.0.2422/mm2-31d1803b0-Windows_NT-Release.zip)
endif ()

FetchContent_Declare(qmaterial URL https://github.com/KomodoPlatform/Qaterial/archive/master.zip)

FetchContent_Declare(jl777-coins
        URL https://github.com/KomodoPlatform/coins/archive/master.zip)

FetchContent_MakeAvailable(mm2 jl777-coins qmaterial)

##! Configure our needs.
if (UNIX)
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/coins COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/mm2 ${CMAKE_CURRENT_SOURCE_DIR}/assets/tools/mm2/mm2 COPYONLY)
else ()
    configure_file(${jl777-coins_SOURCE_DIR}/coins ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/coins COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/mm2.exe ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/mm2.exe COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/msvcp140.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/msvcp140.dll COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/msvcr100.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/msvcr100.dll COPYONLY)
    configure_file(${mm2_SOURCE_DIR}/vcruntime140.dll ${CMAKE_BINARY_DIR}/bin/assets/tools/mm2/vcruntime140.dll COPYONLY)
endif ()

add_subdirectory(vendor/antara-gaming_sdk/modules)

##! Osx bundle icon
set(ICON)
configure_icon_osx(data/osx/atomicdex-desktop.icns ICON atomicdex-desktop.icns)
##! End antara

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

##Lang
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM TRUE)

set(TS_FILES
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_en.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_fr.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_tr.ts
        ${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/atomic_defi_ru.ts)

set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION "${CMAKE_SOURCE_DIR}/atomic_defi_design/assets/languages/")

qt5_create_translation(QM_FILES
        ${PROJECT_SOURCE_DIR}/atomic_defi_design/qml
        ${TS_FILES}
        OPTIONS -source-language en_US -no-obsolete)

message(STATUS "QM FILES -> ${QM_FILES}")
message(STATUS "TS FILES -> ${TS_FILES}")
##! End Lang

##! Atomic QT Shared Deps Between main executable and unit tests
add_library(atomicdex-desktop_shared_deps INTERFACE)
target_sources(atomicdex-desktop_shared_deps INTERFACE
        ##! App
        ${CMAKE_SOURCE_DIR}/src/atomicdex/app.cpp

        ##! Utilities
        ${CMAKE_SOURCE_DIR}/src/atomicdex/utilities/kill.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/utilities/cpprestsdk.utilities.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/utilities/qt.utilities.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/utilities/qt.bindings.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/utilities/security.utilities.cpp

        ##! Constants
        ${CMAKE_SOURCE_DIR}/src/atomicdex/constants/mm2.error.code.cpp

        ##! Config
        ${CMAKE_SOURCE_DIR}/src/atomicdex/config/app.cfg.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/config/coins.cfg.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/config/wallet.cfg.cpp

        ##! Managers
        ${CMAKE_SOURCE_DIR}/src/atomicdex/managers/notification.manager.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/managers/qt.wallet.manager.cpp

        ##! API
        ${CMAKE_SOURCE_DIR}/src/atomicdex/api/ohlc/ohlc.api.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/api/mm2/mm2.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/api/coinpaprika/coinpaprika.cpp

        ##! Models
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.orders.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.orders.proxy.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.candlestick.charts.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.addressbook.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.addressbook.proxy.filter.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.contact.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.orderbook.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.orderbook.proxy.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.portfolio.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.wallet.transactions.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.wallet.transactions.proxy.filter.model.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/models/qt.portfolio.proxy.filter.model.cpp

        ##ToClass

        ##! Widgets
        ${CMAKE_SOURCE_DIR}/src/atomicdex/widgets/dex/qt.market.pairs.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/widgets/dex/qt.orderbook.cpp

        ##! Pages
        ${CMAKE_SOURCE_DIR}/src/atomicdex/pages/qt.trading.page.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/pages/qt.settings.page.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/pages/qt.portfolio.page.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/pages/qt.wallet.page.cpp

        ##! Services
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/price/global.provider.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/price/coinpaprika/coinpaprika.provider.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/price/oracle/band.provider.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/update/update.checker.service.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/ohlc/ohlc.provider.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/mm2/mm2.service.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/internet/internet.checker.service.cpp
        ${CMAKE_SOURCE_DIR}/src/atomicdex/services/ip/ip.checker.service.cpp

        ##! Platform
        $<$<PLATFORM_ID:Darwin>:${CMAKE_SOURCE_DIR}/src/atomicdex/platform/osx/manager.mm>

        ##! QRC
        ${CMAKE_SOURCE_DIR}/qml.qrc

        ##! Linguistic
        ${QM_FILES}
        ${TS_FILES}
        )

target_compile_definitions(atomicdex-desktop_shared_deps
        INTERFACE
        $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>
        $<$<PLATFORM_ID:Windows>:HAS_REMOTE_API>
        $<$<PLATFORM_ID:Windows>:AUTO_DOWNLOAD>
        )


if (DISABLE_GEOBLOCKING)
    message(STATUS "Disabling Geoblocking for dev purpose")
    target_compile_definitions(atomicdex-desktop_shared_deps INTERFACE -DDISABLE_GEOBLOCKING)
endif()
#target_compile_options(atomicdex-desktop_shared_deps INTERFACE -fstandalone-debug)

target_link_libraries(atomicdex-desktop_shared_deps
        INTERFACE
        Qt::Core
        Qt::Quick
        Qt::Svg
        Qt::Charts
        Qt::WebEngine
        Qt::WebEngineCore
        Qt::WebEngineWidgets
        Qt::Widgets
        qzxing
        antara::world
        Boost::random
        Boost::filesystem
        komodo-sodium::sodium
        unofficial-btc::bitcoin
        reproc++
        komodo-date::date
        komodo-folly::folly
        komodo-taskflow::taskflow
        nlohmann_json::nlohmann_json
        #spdlog::spdlog
        #spdlog::spdlog_header_only
        cpprestsdk::cpprest
        Qaterial
        )

target_include_directories(atomicdex-desktop_shared_deps
        INTERFACE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        $<$<PLATFORM_ID:Darwin>:${CMAKE_CURRENT_SOURCE_DIR}/src/osx>
        ${libqr_code_SOURCE_DIR}/src
        )

##! Main executable
add_executable(atomicdex-desktop MACOSX_BUNDLE ${ICON}
        ${CMAKE_CURRENT_SOURCE_DIR}/data/windows/atomicdex-desktop.rc
        main.cpp
        )

##! Testing executable
add_executable(atomicdex-desktop_tests MACOSX_BUNDLE ${ICON}
        src/atomicdex/tests/atomic.dex.tests.cpp
        src/atomicdex/tests/atomic.dex.wallet.config.tests.cpp
        src/atomicdex/tests/atomic.dex.utilities.tests.cpp
        src/atomicdex/tests/atomic.dex.provider.cex.prices.tests.cpp
        src/atomicdex/tests/atomic.dex.qt.utilities.tests.cpp
        src/atomicdex/tests/atomic.dex.provider.cex.prices.api.tests.cpp)

target_link_libraries(atomicdex-desktop
        PRIVATE
        atomicdex-desktop_shared_deps
        $<$<PLATFORM_ID:Darwin>:/usr/local/lib/libcurl.a>
        )

target_include_directories(atomicdex-desktop PUBLIC src)

target_link_libraries(atomicdex-desktop_tests
        PRIVATE
        atomicdex-desktop_shared_deps
        $<$<PLATFORM_ID:Darwin>:/usr/local/lib/libcurl.a>
        doctest::doctest)

##! Setting output directory
set_target_properties(${PROJECT_NAME}
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/"
        )

set_target_properties(${PROJECT_NAME}_tests
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/"
        )


if (NOT APPLE)
    target_precompile_headers(${PROJECT_NAME} PRIVATE src/atomicdex/pch.hpp)
endif ()
#target_enable_tsan(atomicdex-desktop_tests)
#target_enable_asan(atomicdex-desktop)

##! Move assets
if (LINUX)
    get_target_property(exe_runtime_directory_at ${PROJECT_NAME} RUNTIME_OUTPUT_DIRECTORY)
    set(output_dir_at "${exe_runtime_directory_at}/AntaraAtomicDexAppDir")

    magic_game_app_image_generation("${CMAKE_CURRENT_SOURCE_DIR}/data/linux"
            "atomicdex-desktop.desktop"
            "atomicdex-desktop.appdata.xml"
            "atomicdex-desktop_64.png"
            atomicdex-desktop
            AntaraAtomicDexAppDir
            ${CMAKE_CURRENT_SOURCE_DIR}/assets
            )

    magic_game_app_image_generation("${CMAKE_CURRENT_SOURCE_DIR}/data/linux"
            "atomicdex-desktop.desktop"
            "atomicdex-desktop.appdata.xml"
            "atomicdex-desktop_64.png"
            atomicdex-desktop_tests
            AntaraAtomicDexTestsAppDir
            ${CMAKE_CURRENT_SOURCE_DIR}/assets
            )

    set(from_dir "${CMAKE_CURRENT_SOURCE_DIR}/data/linux")
    set(desktop_file "atomicdex-desktop.desktop")
    set(appdata_file "atomicdex-desktop.appdata.xml")
    set(app_icon "atomicdex-desktop-64.png")
    message(STATUS "${output_dir_at}")
    configure_file(${from_dir}/${desktop_file} ${output_dir_at}/usr/share/applications/${desktop_file} COPYONLY)
    configure_file(${from_dir}/${appdata_file} ${output_dir_at}/usr/share/metainfo/${appdata_file} COPYONLY)
    configure_file(${from_dir}/${app_icon} ${output_dir_at}/usr/share/icons/hicolor/64x64/apps/${app_icon} COPYONLY)
    configure_file(${from_dir}/${app_icon} ${output_dir_at}/usr/share/icons/default/64x64/apps/${app_icon} COPYONLY)
endif ()

if (WIN32)
	add_compile_definitions(_CRT_SECURE_NO_WARNINGS)
    file(COPY assets DESTINATION ${CMAKE_BINARY_DIR}/bin/)
    configure_file(wally/wally.dll ${CMAKE_BINARY_DIR}/bin/ COPYONLY)
    set_target_properties(Folly::folly PROPERTIES INTERFACE_COMPILE_OPTIONS "")
    if (CMAKE_BUILD_TYPE MATCHES Release)
        message(STATUS "disabling console")
        target_compile_definitions(atomicdex-desktop PRIVATE WINDOWS_RELEASE_MAIN)
		target_compile_options(atomicdex-desktop PRIVATE -Wno-deprecated-declarations)
        target_link_options(atomicdex-desktop PUBLIC --for-linker -subsystem:windows)
    endif ()
	set(WINDEPLOYQT_PATH "")
	if (CONAN_ENABLED)
		set(WINDEPLOYQT_PATH ${CONAN_QT_ROOT}/bin/windeployqt.exe)
	else()
		set(WINDEPLOYQT_PATH $ENV{QT_INSTALL_CMAKE_PATH}/bin/windeployqt.exe)
	endif()
	
	if (EXISTS ${WINDEPLOYQT_PATH})
		message(STATUS "windeployqt path is -> ${WINDEPLOYQT_PATH}")
	else ()
		message(FATAL_ERROR "Didn't find windeployqt ${WINDEPLOYQT_PATH}")
	endif ()
	#bin --qmldir
	add_custom_command(TARGET atomicdex-desktop PRE_BUILD
                   COMMAND ${CMAKE_COMMAND} -E copy_directory
                       ${CMAKE_SOURCE_DIR}/ci_tools_atomic_dex/windows_misc $<TARGET_FILE_DIR:atomicdex-desktop>)
	add_custom_command(TARGET atomicdex-desktop
        POST_BUILD
        COMMAND ${WINDEPLOYQT_PATH} ${CMAKE_BINARY_DIR}/bin --qmldir ${CMAKE_SOURCE_DIR}/atomic_defi_design/qml
        )
endif ()

if (APPLE)
    file(COPY assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.app/Contents/Resources)
    file(COPY assets DESTINATION ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}_tests.app/Contents/Resources)
    include(data/osx/atomicdex_install.cmake)
endif ()
