##! Dependancies
include(FetchContent)

if (WIN32)
    find_package(ZLIB)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Override option" FORCE)
endif ()

find_package(EnTT REQUIRED)
find_package(fmt REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(range-v3 REQUIRED)
find_package(date REQUIRED)
find_package(doctest REQUIRED)
find_package(folly REQUIRED)
find_package(spdlog REQUIRED)
find_package(cpprestsdk REQUIRED)
find_package(Boost COMPONENTS filesystem random system REQUIRED)
add_library(komodo-taskflow INTERFACE)
if (CONAN_ENABLED)
    find_package(Taskflow REQUIRED)
    target_link_libraries(komodo-taskflow INTERFACE Taskflow::Taskflow)
endif ()
add_library(komodo-taskflow::taskflow ALIAS komodo-taskflow)
if (CONAN_ENABLED)
    if (NOT TARGET Boost::filesystem)
        add_library(Boost::filesystem INTERFACE IMPORTED)
        if (WIN32)
            target_link_libraries(Boost::filesystem INTERFACE
                    CONAN_LIB::Boost_libboost_filesystem
                    CONAN_LIB::Boost_libboost_system
                    Boost::Boost)
        else ()

            target_link_libraries(Boost::filesystem INTERFACE
                    CONAN_LIB::Boost_boost_filesystem
                    CONAN_LIB::Boost_boost_system
                    Boost::Boost)
        endif ()
    endif ()

    if (NOT TARGET Boost::random)
        add_library(Boost::random INTERFACE IMPORTED)
        if (WIN32)
            target_link_libraries(Boost::random INTERFACE CONAN_LIB::Boost_libboost_random)
        else ()
            target_link_libraries(Boost::random INTERFACE CONAN_LIB::Boost_boost_random)
        endif ()
    endif ()
endif ()

add_library(komodo-date INTERFACE)
if (CONAN_ENABLED)
    target_link_libraries(komodo-date INTERFACE date::date)
else ()
    target_link_libraries(komodo-date INTERFACE date::tz)
endif ()
add_library(komodo-date::date ALIAS komodo-date)

add_library(komodo-folly INTERFACE)
if (CONAN_ENABLED)
    target_link_libraries(komodo-folly INTERFACE Folly::Folly)
else ()
    target_link_libraries(komodo-folly INTERFACE Folly::folly Folly::folly_deps)
endif ()
add_library(komodo-folly::folly ALIAS komodo-folly)

find_package(Qt5 5.15 COMPONENTS Core Quick LinguistTools Svg Charts WebEngine WebEngineCore WebEngineWidgets Widgets REQUIRED)

#find_package(Qt5)

set(BUILD_TESTING OFF CACHE BOOL "Override option" FORCE)
set(REPROC++ ON CACHE BOOL "" FORCE)

FetchContent_Declare(
        doom_st
        URL https://github.com/KomodoPlatform/strong_type/archive/1.0.2.tar.gz
)

FetchContent_Declare(
        doom_meta
        URL https://github.com/KomodoPlatform/meta/archive/master.zip
)

FetchContent_Declare(
        reproc
        URL https://github.com/KomodoPlatform/reproc/archive/v13.0.1.zip
)

set(EXPECTED_ENABLE_TESTS OFF CACHE BOOL "Override option" FORCE)

FetchContent_Declare(
        expected
        URL https://github.com/Milerius/expected/archive/patch-1.zip
)

FetchContent_Declare(
        refl-cpp
        URL https://github.com/KomodoPlatform/refl-cpp/archive/v0.6.5.zip
)

FetchContent_MakeAvailable(doom_st refl-cpp doom_meta)

add_library(doctest INTERFACE)
target_link_libraries(doctest INTERFACE doctest::doctest)

add_library(antara_entt INTERFACE)
target_link_libraries(antara_entt INTERFACE EnTT::EnTT)
add_library(antara::entt ALIAS antara_entt)

add_library(refl-cpp INTERFACE)
target_include_directories(refl-cpp INTERFACE ${refl-cpp_SOURCE_DIR})
add_library(antara::refl-cpp ALIAS refl-cpp)

FetchContent_Declare(libqr_code
        URL https://github.com/KomodoPlatform/qzxing/archive/master.zip)


FetchContent_GetProperties(libqr_code)
if (NOT libqr_code_POPULATED)
    FetchContent_Populate(libqr_code)
    add_subdirectory(${libqr_code_SOURCE_DIR}/src ${libqr_code_BINARY_DIR} EXCLUDE_FROM_ALL)
    if (UNIX AND NOT APPLE)
        target_compile_options(qzxing PRIVATE -stdlib=libc++)
        target_link_options(qzxing PRIVATE -stdlib=libc++ -lc++abi)
    endif()
endif ()

FetchContent_GetProperties(reproc)
if (NOT reproc_POPULATED)
    FetchContent_Populate(reproc)
    add_subdirectory(${reproc_SOURCE_DIR} ${reproc_BINARY_DIR} EXCLUDE_FROM_ALL)
endif ()

FetchContent_GetProperties(expected)
if (NOT expected_POPULATED)
    FetchContent_Populate(expected)
    add_subdirectory(${expected_SOURCE_DIR} ${expected_BINARY_DIR} EXCLUDE_FROM_ALL)
endif ()


##! Sodium
add_library(komodo-sodium INTERFACE)
if (CONAN_ENABLED)
    find_package(libsodium REQUIRED)
else ()
     find_package(unofficial-sodium CONFIG REQUIRED)
    target_link_libraries(komodo-sodium INTERFACE unofficial-sodium::sodium)
endif ()
add_library(komodo-sodium::sodium ALIAS komodo-sodium)


## Unofficial BTC
add_library(unofficial-bitcoin INTERFACE)
if (WIN32)
    target_link_directories(unofficial-bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally)
    target_link_libraries(unofficial-bitcoin INTERFACE wally)
    target_include_directories(unofficial-bitcoin INTERFACE ${PROJECT_SOURCE_DIR}/wally)
else ()
    find_library(unofficial-secp secp256k1)
    find_library(unofficial-wally wallycore)
    find_path(unofficial-wally-headers wally_core.h)
    target_link_libraries(unofficial-bitcoin INTERFACE ${unofficial-wally} ${unofficial-secp})
    target_include_directories(unofficial-bitcoin INTERFACE ${unofficial-wally-headers})
    message(STATUS "Found wally -> ${unofficial-wally} ${unofficial-wally-headers}")
endif ()
add_library(unofficial-btc::bitcoin ALIAS unofficial-bitcoin)