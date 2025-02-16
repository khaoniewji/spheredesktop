cmake_minimum_required(VERSION 3.16)
project(sphere_desktop VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 COMPONENTS
    Core
    Quick
    QuickControls2
    Gui
    OpenGL
    REQUIRED
)

set(SOURCES
    src/main.cpp
    src/gui/mainscreen.cpp
    src/gui/taskbar.cpp
    src/gui/desktopmanager.cpp
)

set(HEADERS
    src/gui/mainscreen.hpp
    src/gui/taskbar.hpp
    src/gui/desktopmanager.hpp
)

qt_add_resources(RESOURCES
    resources/shared.qrc
)

add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
    ${RESOURCES}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Gui
    Qt6::OpenGL
)

if(WIN32)
    target_link_libraries(${PROJECT_NAME} PRIVATE
        opengl32
    )
endif()

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Optional: Enable optimizations for Release builds
if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:/O2 /GL /Gy /Oi /Ot>
    )
    target_link_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:/LTCG>
    )
endif()
