cmake_minimum_required(VERSION 3.4.1)

#############################prepare for using of opencv static library####################
#first step to use opencv
set(OpenCV_STATIC ON)
#second step to use opencv
# TODO please change me!
set(OpenCV_DIR F:/Project_Demo/OpenCV/OpenCV-android-sdk/sdk/native/jni)
#third step to use opencv
find_package(OpenCV REQUIRED)
#############################the native-lib shared library#################################
# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

include_directories(src/main/cpp/include)

add_library( # Sets the name of the library.
        smart_cropper

        # Sets the library as a shared library.
        SHARED

        # Provides a relative path to your source file(s).
        src/main/cpp/android_utils.cpp
        src/main/cpp/Scanner.cpp
        src/main/cpp/smart_cropper.cpp)

add_library( # Sets the name of the library.
        flutter_opencv

        # Sets the library as a shared library.
        SHARED

        # Provides a relative path to your source file(s).
        ../ios/Classes/native_add.cpp)

# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library( # Sets the name of the path variable.
        log-lib

        # Specifies the name of the NDK library that
        # you want CMake to locate.
        log)

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

target_link_libraries( # Specifies the target library.
        smart_cropper

        #foutth step to use opencv link opencv
        ${OpenCV_LIBS}
        # Links the target library to the log library
        # included in the NDK.
        ${log-lib})

target_link_libraries( # Specifies the target library.
        flutter_opencv

        #foutth step to use opencv link opencv
        ${OpenCV_LIBS}
        # Links the target library to the log library
        # included in the NDK.
        ${log-lib})