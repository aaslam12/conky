#
# Conky, a system monitor, based on torsmo
#
# Please see COPYING for details
#
# Copyright (c) 2005-2024 Brenden Matthews, et. al. (see AUTHORS) All rights
# reserved.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details. You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

include(FindPkgConfig)
include(CheckFunctionExists)
include(CheckIncludeFiles)
include(CheckSymbolExists)

# Check for some headers
check_include_files(sys/statfs.h HAVE_SYS_STATFS_H)
check_include_files(sys/param.h HAVE_SYS_PARAM_H)
check_include_files(sys/inotify.h HAVE_SYS_INOTIFY_H)
check_include_files(dirent.h HAVE_DIRENT_H)

# Check for some functions
check_function_exists(strndup HAVE_STRNDUP)

check_symbol_exists(pipe2 "unistd.h" HAVE_PIPE2)
check_symbol_exists(O_CLOEXEC "fcntl.h" HAVE_O_CLOEXEC)

if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
  check_symbol_exists(statfs64 "sys/mount.h" HAVE_STATFS64)
else(CMAKE_SYSTEM_NAME MATCHES "Darwin")
  check_symbol_exists(statfs64 "sys/statfs.h" HAVE_STATFS64)
endif(CMAKE_SYSTEM_NAME MATCHES "Darwin")

ac_search_libs(clock_gettime "time.h" CLOCK_GETTIME_LIB "rt")

if(NOT DEFINED CLOCK_GETTIME_LIB)
  if(NOT CMAKE_SYSTEM_NAME MATCHES "Darwin")
    message(FATAL_ERROR "clock_gettime not found.")
  endif(NOT CMAKE_SYSTEM_NAME MATCHES "Darwin")
else(NOT DEFINED CLOCK_GETTIME_LIB)
  set(HAVE_CLOCK_GETTIME 1)
endif(NOT DEFINED CLOCK_GETTIME_LIB)

set(conky_libs ${conky_libs} ${CLOCK_GETTIME_LIB})

# standard path to search for includes
set(INCLUDE_SEARCH_PATH /usr/include /usr/local/include)

# Detect CI
if(DEFINED ENV{CI})
  # For GitHub actions CI=true is set
  set(ENV_IS_CI true)
  mark_as_advanced(ENV_IS_CI)
endif()

# Set system vars
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(OS_LINUX true)
else(CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(OS_LINUX false)
endif(CMAKE_SYSTEM_NAME MATCHES "Linux")

if(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
  set(OS_FREEBSD true)
  set(conky_libs ${conky_libs} -lkvm -ldevstat -linotify)

  if(BUILD_IRC)
    set(conky_libs ${conky_libs} -lssl -lcrypto)
  endif(BUILD_IRC)
else(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")
  set(OS_FREEBSD false)
endif(CMAKE_SYSTEM_NAME MATCHES "FreeBSD")

if(CMAKE_SYSTEM_NAME MATCHES "DragonFly")
  set(OS_DRAGONFLY true)
  set(conky_libs ${conky_libs} -ldevstat)
else(CMAKE_SYSTEM_NAME MATCHES "DragonFly")
  set(OS_DRAGONFLY false)
endif(CMAKE_SYSTEM_NAME MATCHES "DragonFly")

if(CMAKE_SYSTEM_NAME MATCHES "OpenBSD")
  set(OS_OPENBSD true)
  set(conky_libs ${conky_libs} -lkvm)
else(CMAKE_SYSTEM_NAME MATCHES "OpenBSD")
  set(OS_OPENBSD false)
endif(CMAKE_SYSTEM_NAME MATCHES "OpenBSD")

if(CMAKE_SYSTEM_NAME MATCHES "SunOS")
  set(OS_SOLARIS true)
  set(conky_libs ${conky_libs} -lkstat)
else(CMAKE_SYSTEM_NAME MATCHES "SunOS")
  set(OS_SOLARIS false)
endif(CMAKE_SYSTEM_NAME MATCHES "SunOS")

if(CMAKE_SYSTEM_NAME MATCHES "NetBSD")
  set(OS_NETBSD true)
  set(conky_libs ${conky_libs} -lkvm)
else(CMAKE_SYSTEM_NAME MATCHES "NetBSD")
  set(OS_NETBSD false)
endif(CMAKE_SYSTEM_NAME MATCHES "NetBSD")

if(CMAKE_SYSTEM_NAME MATCHES "Haiku")
  set(OS_HAIKU true)
  set(conky_libs ${conky_libs} -lnetwork)
else(CMAKE_SYSTEM_NAME MATCHES "Haiku")
  set(OS_HAIKU false)
endif(CMAKE_SYSTEM_NAME MATCHES "Haiku")

if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
  set(OS_DARWIN true)
else(CMAKE_SYSTEM_NAME MATCHES "Darwin")
  set(OS_DARWIN false)
endif(CMAKE_SYSTEM_NAME MATCHES "Darwin")

if(NOT OS_LINUX
  AND NOT OS_FREEBSD
  AND NOT OS_OPENBSD
  AND NOT OS_NETBSD
  AND NOT OS_DRAGONFLY
  AND NOT OS_SOLARIS
  AND NOT OS_HAIKU
  AND NOT OS_DARWIN)
  message(
    FATAL_ERROR
    "Your platform, '${CMAKE_SYSTEM_NAME}', is not currently supported.  Patches are welcome."
  )
endif(NOT
  OS_LINUX
  AND
  NOT
  OS_FREEBSD
  AND
  NOT
  OS_OPENBSD
  AND
  NOT
  OS_NETBSD
  AND
  NOT
  OS_DRAGONFLY
  AND
  NOT
  OS_SOLARIS
  AND
  NOT
  OS_HAIKU
  AND
  NOT
  OS_DARWIN)

if(OS_LINUX)
  check_include_files("linux/sockios.h" HAVE_LINUX_SOCKIOS_H)
endif(OS_LINUX)

# Handle Open Sound System
if(BUILD_OPENSOUNDSYS)
  if(OS_LINUX)
    check_include_files("linux/soundcard.h" HAVE_SOUNDCARD_H)
  elseif(OS_OPENBSD OR OS_NETBSD)
    check_include_files("soundcard.h" HAVE_SOUNDCARD_H)
    # OpenBSD (and FreeBSD?) provide emulation layer on top of sndio.
    if(HAVE_SOUNDCARD_H)
      find_library(OSS_AUDIO_LIB
        NAMES ossaudio
        PATHS /usr/lib
        /usr/local/lib)
      set(conky_libs ${conky_libs} ${OSS_AUDIO_LIB})
    endif(HAVE_SOUNDCARD_H)
  else(OS_LINUX)
    check_include_files("sys/soundcard.h" HAVE_SOUNDCARD_H)
  endif(OS_LINUX)
endif(BUILD_OPENSOUNDSYS)

if(BUILD_I18N)
  include(FindIntl)
  find_package(Intl)

  if(NOT Intl_FOUND)
    if(OS_DARWIN)
      message(WARNING "Try running `brew install gettext` for I18N support")
      # Should be present by default everywhere else
    endif(OS_DARWIN)
    message(FATAL_ERROR "Unable to find libintl")
  endif(NOT Intl_FOUND)

  include_directories(${Intl_INCLUDE_DIRS})
  set(conky_libs ${conky_libs} ${Intl_LIBRARIES})
endif(BUILD_I18N)

if(BUILD_NCURSES AND OS_DARWIN)
  set(conky_libs ${conky_libs} -lncurses)
endif(BUILD_NCURSES AND OS_DARWIN)

if(BUILD_WLAN AND OS_DARWIN)
  find_library(CW CoreWLAN)
  find_library(NS Foundation)
  set(conky_libs ${conky_libs} ${CW})
  set(conky_libs ${conky_libs} ${NS})
endif(BUILD_WLAN AND OS_DARWIN)

if(OS_DARWIN AND BUILD_IPGFREQ)
  find_library(IPG IntelPowerGadget)
  set(conky_libs ${conky_libs} ${IPG})
endif(OS_DARWIN AND BUILD_IPGFREQ)

if(BUILD_MATH)
  set(conky_libs ${conky_libs} -lm)
endif(BUILD_MATH)

if(BUILD_ICAL)
  check_include_files(libical/ical.h ICAL_H_)

  if(NOT ICAL_H_)
    message(FATAL_ERROR "Unable to find libical")
  endif(NOT ICAL_H_)

  set(conky_libs ${conky_libs} -lical)
endif(BUILD_ICAL)

if(BUILD_IRC)
  find_path(IRC_H_N libircclient.h PATHS /usr/include/libircclient)
  find_path(IRC_H_S libircclient.h PATHS /usr/include)

  if(IRC_H_N)
    include_directories(${IRC_H_N})
  endif(IRC_H_N)

  if(IRC_H_N OR IRC_H_S)
    set(IRC_H_ true)
  else()
    message(FATAL_ERROR "Unable to find libircclient")
  endif(IRC_H_N OR IRC_H_S)

  set(conky_libs ${conky_libs} -lircclient)
endif(BUILD_IRC)

if(BUILD_IPV6)
  find_file(IF_INET6 if_inet6 PATHS /proc/net)

  if(NOT IF_INET6)
    message(WARNING "/proc/net/if_inet6 unavailable")
  endif(NOT IF_INET6)
endif(BUILD_IPV6)

if(BUILD_HTTP)
  pkg_check_modules(MICROHTTPD REQUIRED libmicrohttpd>=0.9.25)
  set(conky_libs ${conky_libs} ${MICROHTTPD_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${MICROHTTPD_INCLUDE_DIRS})
endif(BUILD_HTTP)

if(BUILD_NCURSES)
  set(CURSES_NEED_NCURSES TRUE)

  find_path(CURSES_INCLUDE_PATH
    NAMES curses.h
    PATH_SUFFIXES ncurses
    PATHS /usr/include /usr/local/include /usr/pkg/include
  )

  find_library(CURSES_LIBRARY
    NAMES curses
    PATHS /lib /usr/lib /usr/local/lib /usr/pkg/lib
  )

  find_package(PkgConfig QUIET)
  if(PKG_CONFIG_FOUND)
    pkg_search_module(NCURSES ncurses)
    set(CURSES_LIBRARY ${NCURSES_LDFLAGS})
  endif()

  if(NOT CURSES_LIBRARY OR NOT CURSES_INCLUDE_PATH)
    message(FATAL_ERROR "Unable to find curses library")
  else(NOT CURSES_LIBRARY OR NOT CURSES_INCLUDE_PATH)
    message(STATUS "curses found.")
    message(STATUS "  include: ${CURSES_INCLUDE_PATH}")
    message(STATUS "  lib: ${CURSES_LIBRARY}")
  endif(NOT CURSES_LIBRARY OR NOT CURSES_INCLUDE_PATH)

  set(conky_libs ${conky_libs} ${CURSES_LIBRARY})
  set(conky_includes ${conky_includes} ${CURSES_INCLUDE_PATH})

  if(OS_NETBSD)
    cmake_path(GET CURSES_INCLUDE_PATH PARENT_PATH CURSES_PARENT)
    set(conky_includes ${conky_includes} ${CURSES_PARENT})
  endif(OS_NETBSD)
endif(BUILD_NCURSES)

if(BUILD_MYSQL)
  find_path(mysql_INCLUDE_PATH
    mysql.h
    ${INCLUDE_SEARCH_PATH}
    /usr/include/mysql
    /usr/local/include/mysql)

  if(NOT mysql_INCLUDE_PATH)
    message(FATAL_ERROR "Unable to find mysql.h")
  endif(NOT mysql_INCLUDE_PATH)

  set(conky_includes ${conky_includes} ${mysql_INCLUDE_PATH})
  find_library(MYSQLCLIENT_LIB
    NAMES mysqlclient
    PATHS /usr/lib
    /usr/lib64
    /usr/lib/mysql
    /usr/lib64/mysql
    /usr/local/lib
    /usr/local/lib64
    /usr/local/lib/mysql
    /usr/local/lib64/mysql)

  if(NOT MYSQLCLIENT_LIB)
    message(FATAL_ERROR "Unable to find mysqlclient library")
  endif(NOT MYSQLCLIENT_LIB)

  set(conky_libs ${conky_libs} ${MYSQLCLIENT_LIB})
endif(BUILD_MYSQL)

if(BUILD_WLAN AND OS_LINUX)
  set(CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE)
  check_include_files(iwlib.h IWLIB_H)

  if(NOT IWLIB_H)
    message(FATAL_ERROR "Unable to find iwlib.h")
  endif(NOT IWLIB_H)

  find_library(IWLIB_LIB NAMES iw)

  if(NOT IWLIB_LIB)
    message(FATAL_ERROR "Unable to find libiw.so")
  endif(NOT IWLIB_LIB)

  set(conky_libs ${conky_libs} ${IWLIB_LIB})
  check_function_exists(iw_sockets_open IWLIB_SOCKETS_OPEN_FUNC)
endif(BUILD_WLAN AND OS_LINUX)

if(BUILD_PORT_MONITORS)
  check_function_exists(getnameinfo HAVE_GETNAMEINFO)

  if(NOT HAVE_GETNAMEINFO)
    message(FATAL_ERROR "could not find getnameinfo()")
  endif(NOT HAVE_GETNAMEINFO)

  check_include_files(
    "netdb.h;netinet/in.h;netinet/tcp.h;sys/socket.h;arpa/inet.h"
    HAVE_PORTMON_HEADERS)

  if(NOT HAVE_PORTMON_HEADERS)
    message(FATAL_ERROR "missing needed network header(s) for port monitoring")
  endif(NOT HAVE_PORTMON_HEADERS)
endif(BUILD_PORT_MONITORS)

# Check for iconv
if(BUILD_ICONV)
  check_include_files(iconv.h HAVE_ICONV_H)
  find_library(ICONV_LIBRARY NAMES iconv)

  if(NOT ICONV_LIBRARY)
    # maybe iconv() is provided by libc
    set(ICONV_LIBRARY ""
      CACHE FILEPATH
      "Path to the iconv library, if iconv is not provided by libc"
      FORCE)
  endif(NOT ICONV_LIBRARY)

  set(CMAKE_REQUIRED_LIBRARIES ${ICONV_LIBRARY})
  check_function_exists(iconv ICONV_FUNC)

  if(HAVE_ICONV_H AND ICONV_FUNC)
    set(conky_includes ${conky_includes} ${ICONV_INCLUDE_DIR})
    set(conky_libs ${conky_libs} ${ICONV_LIBRARY})
  else(HAVE_ICONV_H AND ICONV_FUNC)
    message(FATAL_ERROR "Unable to find iconv library")
  endif(HAVE_ICONV_H AND ICONV_FUNC)
endif(BUILD_ICONV)

# check for Xlib
if(BUILD_X11)
  include(FindX11)
  find_package(X11)

  if(X11_FOUND)
    set(conky_includes ${conky_includes} ${X11_INCLUDE_DIR})
    set(conky_libs ${conky_libs} ${X11_LIBRARIES})

    # check for Xdamage
    if(BUILD_XDAMAGE)
      if(NOT X11_Xdamage_FOUND)
        message(FATAL_ERROR "Unable to find Xdamage library")
      endif(NOT X11_Xdamage_FOUND)

      if(NOT X11_Xfixes_FOUND)
        message(FATAL_ERROR "Unable to find Xfixes library")
      endif(NOT X11_Xfixes_FOUND)

      set(conky_libs ${conky_libs} ${X11_Xdamage_LIB} ${X11_Xfixes_LIB})
    endif(BUILD_XDAMAGE)

    if(BUILD_XSHAPE)
      if(NOT X11_Xshape_FOUND)
        message(FATAL_ERROR "Unable to find Xshape library")
      endif(NOT X11_Xshape_FOUND)

      set(conky_libs ${conky_libs} ${X11_Xshape_LIB})
    endif(BUILD_XSHAPE)

    # check for Xft
    if(BUILD_XFT)
      if(FREETYPE_INCLUDE_DIR_freetype2)
        set(FREETYPE_FOUND true)
        set(conky_includes ${conky_includes} ${FREETYPE_INCLUDE_DIR_freetype2})
      else(FREETYPE_INCLUDE_DIR_freetype2)
        message(FATAL_ERROR "Unable to find freetype library")
      endif(FREETYPE_INCLUDE_DIR_freetype2)

      if(NOT X11_Xft_FOUND)
        message(FATAL_ERROR "Unable to find Xft library")
      endif(NOT X11_Xft_FOUND)

      find_package(Fontconfig REQUIRED)

      set(conky_libs ${conky_libs} ${X11_Xft_LIB} ${Fontconfig_LIBRARIES})
      set(conky_includes ${conky_includes} ${FREETYPE_INCLUDE_DIR_freetype2} ${Fontconfig_INCLUDE_DIRS})
    endif(BUILD_XFT)

    # check for Xdbe
    if(BUILD_XDBE)
      if(NOT X11_Xext_FOUND)
        message(FATAL_ERROR "Unable to find Xext library (needed for Xdbe)")
      endif(NOT X11_Xext_FOUND)

      set(conky_libs ${conky_libs} ${X11_Xext_LIB})
    endif(BUILD_XDBE)

    # check for Xinerama
    if(BUILD_XINERAMA)
      if(NOT X11_Xinerama_FOUND)
        message(FATAL_ERROR "Unable to find Xinerama library")
      endif(NOT X11_Xinerama_FOUND)

      set(conky_libs ${conky_libs} ${X11_Xinerama_LIB})
    endif(BUILD_XINERAMA)

    # check for Xfixes
    if(BUILD_XFIXES)
      if(NOT X11_Xfixes_FOUND)
        message(FATAL_ERROR "Unable to find Xfixes library")
      endif(NOT X11_Xfixes_FOUND)

      set(conky_libs ${conky_libs} ${X11_Xfixes_LIB})
    endif(BUILD_XFIXES)

    # check for Xinput
    if(BUILD_XINPUT)
      if(NOT X11_Xinput_FOUND)
        message(FATAL_ERROR "Unable to find Xinput library")
      endif(NOT X11_Xinput_FOUND)

      set(conky_libs ${conky_libs} ${X11_Xinput_LIB})
    endif(BUILD_XINPUT)

    if(X11_xcb_FOUND)
      set(HAVE_XCB true)
      set(conky_libs ${conky_libs} ${X11_xcb_LIB})
      set(conky_includes ${conky_includes} ${X11_xcb_INCLUDE_PATH})

      if(X11_xcb_errors_FOUND)
        set(HAVE_XCB_ERRORS true)
        set(conky_libs ${conky_libs} ${X11_xcb_LIB} ${X11_xcb_errors_LIB})
      else(X11_xcb_errors_FOUND)
        set(HAVE_XCB_ERRORS false)
      endif(X11_xcb_errors_FOUND)
    else(X11_xcb_FOUND)
      set(HAVE_XCB false)
    endif(X11_xcb_FOUND)
  else(X11_FOUND)
    message(FATAL_ERROR "Unable to find X11 library")
  endif(X11_FOUND)
endif(BUILD_X11)

if(BUILD_WAYLAND)
  find_package(Wayland REQUIRED)
  set(conky_libs ${conky_libs} ${Wayland_CLIENT_LIBRARY})
  set(conky_includes ${conky_includes} ${Wayland_CLIENT_INCLUDE_DIR})

  find_package(PkgConfig)

  pkg_check_modules(wayland-protocols QUIET wayland-protocols>=1.13)

  if(Wayland_FOUND AND wayland-protocols_FOUND)
    # find Wayland protocols
    pkg_get_variable(Wayland_PROTOCOLS_DIR wayland-protocols pkgdatadir)

    # find 'wayland-scanner' executable
    pkg_get_variable(Wayland_SCANNER wayland-scanner wayland_scanner)
    if(NOT Wayland_SCANNER)
      message(FATAL_ERROR "Unable to find wayland-scanner")
    endif(NOT Wayland_SCANNER)
  else(Wayland_FOUND AND wayland-protocols_FOUND)
    message(FATAL_ERROR "Unable to find wayland or wayland protocols")
  endif(Wayland_FOUND AND wayland-protocols_FOUND)

  if(OS_DARWIN OR OS_DRAGONFLY OR OS_FREEBSD OR OS_NETBSD OR OS_OPENBSD)
    pkg_check_modules(EPOLL REQUIRED epoll-shim)
    set(conky_libs ${conky_libs} ${EPOLL_LINK_LIBRARIES})
    set(conky_includes ${conky_includes} ${EPOLL_INCLUDE_DIRS})
  endif(OS_DARWIN OR OS_DRAGONFLY OR OS_FREEBSD OR OS_NETBSD OR OS_OPENBSD)

  pkg_check_modules(CAIRO REQUIRED cairo)
  set(conky_libs ${conky_libs} ${CAIRO_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${CAIRO_INCLUDE_DIR})

  pkg_check_modules(PANGO REQUIRED pango)
  set(conky_libs ${conky_libs} ${PANGO_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${PANGO_INCLUDE_DIRS})

  pkg_check_modules(PANGOCAIRO pangocairo)
  set(conky_libs ${conky_libs} ${PANGOCAIRO_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${PANGOCAIRO_INCLUDE_DIRS})

  pkg_check_modules(PANGOFC pangofc)
  set(conky_libs ${conky_libs} ${PANGOFC_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${PANGOFC_INCLUDE_DIRS})

  pkg_check_modules(PANGOFT2 pangoft2)
  set(conky_libs ${conky_libs} ${PANGOFT2_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${PANGOFT2_INCLUDE_DIRS})
endif(BUILD_WAYLAND)

find_package(Lua "5.3" REQUIRED)

set(conky_libs ${conky_libs} ${LUA_LIBRARIES})
set(conky_includes ${conky_includes} ${LUA_INCLUDE_DIR})
include_directories(3rdparty/toluapp/include)

# Check for libraries used by Lua bindings
if(BUILD_LUA_CAIRO)
  pkg_check_modules(CAIRO REQUIRED cairo>=1.14)
  set(luacairo_libs ${CAIRO_LINK_LIBRARIES} ${LUA_LIBRARIES})
  set(luacairo_includes ${CAIRO_INCLUDE_DIRS} ${LUA_INCLUDE_DIR})

  if(BUILD_LUA_CAIRO_XLIB)
    pkg_check_modules(CAIROXLIB REQUIRED cairo-xlib)
    set(luacairo_libs ${CAIROXLIB_LINK_LIBRARIES} ${luacairo_libs})
    set(luacairo_includes ${CAIROXLIB_INCLUDE_DIRS} ${luacairo_includes})
  endif(BUILD_LUA_CAIRO_XLIB)

  find_program(APP_PATCH patch)

  if(NOT APP_PATCH)
    message(FATAL_ERROR "Unable to find program 'patch'")
  endif(NOT APP_PATCH)
endif(BUILD_LUA_CAIRO)

if(BUILD_LUA_IMLIB2)
  pkg_search_module(IMLIB2 REQUIRED imlib2 Imlib2)
  set(luaimlib2_libs ${IMLIB2_LIBS} ${IMLIB2_LDFLAGS} ${LUA_LIBRARIES})
  set(luaimlib2_includes
    ${IMLIB2_INCLUDE_DIRS}
    ${LUA_INCLUDE_DIR}
    ${X11_INCLUDE_DIR})
endif(BUILD_LUA_IMLIB2)

if(BUILD_LUA_RSVG)
  pkg_check_modules(RSVG REQUIRED librsvg-2.0>=2.52)
  set(luarsvg_libs ${RSVG_LINK_LIBRARIES} ${LUA_LIBRARIES})
  set(luarsvg_includes ${RSVG_INCLUDE_DIRS} ${LUA_INCLUDE_DIR})
endif(BUILD_LUA_RSVG)

if(BUILD_AUDACIOUS)
  set(WANT_GLIB true)
  pkg_check_modules(NEW_AUDACIOUS audacious>=1.4.0)

  if(NEW_AUDACIOUS_FOUND)
    pkg_check_modules(AUDACIOUS REQUIRED audclient>=1.4.0)
    pkg_check_modules(DBUS_GLIB REQUIRED dbus-glib-1)
  else(NEW_AUDACIOUS_FOUND)
    pkg_check_modules(AUDACIOUS REQUIRED audacious<1.4.0)
  endif(NEW_AUDACIOUS_FOUND)

  set(conky_libs ${conky_libs} ${AUDACIOUS_LINK_LIBRARIES} ${DBUS_GLIB_LIBRARIES})
  set(conky_includes
    ${conky_includes}
    ${AUDACIOUS_INCLUDE_DIRS}
    ${DBUS_GLIB_INCLUDE_DIRS})
endif(BUILD_AUDACIOUS)

if(BUILD_XMMS2)
  pkg_check_modules(XMMS2 REQUIRED xmms2-client>=0.6)
  set(conky_libs ${conky_libs} ${XMMS2_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${XMMS2_INCLUDE_DIRS})
endif(BUILD_XMMS2)

if(BUILD_CURL)
  set(WANT_CURL true)
endif(BUILD_CURL)

if(BUILD_RSS)
  set(WANT_CURL true)
  set(WANT_LIBXML2 true)
endif(BUILD_RSS)

if(BUILD_NVIDIA)
  find_path(XNVCtrl_INCLUDE_PATH NVCtrl/NVCtrl.h ${INCLUDE_SEARCH_PATH})
  find_library(XNVCtrl_LIB NAMES XNVCtrl)

  if(XNVCtrl_INCLUDE_PATH AND XNVCtrl_LIB)
    set(XNVCtrl_FOUND true)
    set(conky_libs ${conky_libs} ${XNVCtrl_LIB})
    set(conky_includes ${conky_includes} ${XNVCtrl_INCLUDE_PATH})
  else(XNVCtrl_INCLUDE_PATH AND XNVCtrl_LIB)
    message(FATAL_ERROR "Unable to find XNVCtrl library")
  endif(XNVCtrl_INCLUDE_PATH AND XNVCtrl_LIB)
endif(BUILD_NVIDIA)

if(BUILD_IMLIB2)
  pkg_search_module(IMLIB2 REQUIRED imlib2 Imlib2)
  set(conky_libs ${conky_libs} ${IMLIB2_LIBS} ${IMLIB2_LDFLAGS})
  set(conky_includes ${conky_includes} ${IMLIB2_INCLUDE_DIRS})
endif(BUILD_IMLIB2)

if(BUILD_JOURNAL)
  pkg_search_module(SYSTEMD REQUIRED libsystemd>=205 libsystemd-journal>=205)
  set(conky_libs ${conky_libs} ${SYSTEMD_LIB} ${SYSTEMD_LDFLAGS})
  set(conky_includes ${conky_includes} ${SYSTEMD_INCLUDE_DIRS})
endif(BUILD_JOURNAL)

if(BUILD_PULSEAUDIO)
  pkg_check_modules(PULSEAUDIO REQUIRED libpulse)
  set(conky_libs ${conky_libs} ${PULSEAUDIO_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${PULSEAUDIO_INCLUDE_DIRS})
endif(BUILD_PULSEAUDIO)

if(WANT_CURL)
  pkg_check_modules(CURL REQUIRED libcurl)
  set(conky_libs ${conky_libs} ${CURL_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${CURL_INCLUDE_DIRS})
endif(WANT_CURL)

# Common libraries
if(WANT_GLIB)
  pkg_check_modules(GLIB REQUIRED glib-2.0>=2.36)
  set(conky_libs ${conky_libs} ${GLIB_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${GLIB_INCLUDE_DIRS})
endif(WANT_GLIB)

if(WANT_CURL)
  pkg_check_modules(CURL REQUIRED libcurl)
  set(conky_libs ${conky_libs} ${CURL_LINK_LIBRARIES})
  set(conky_includes ${conky_includes} ${CURL_INCLUDE_DIRS})
endif(WANT_CURL)

if(WANT_LIBXML2)
  include(FindLibXml2)

  if(NOT LIBXML2_FOUND)
    message(FATAL_ERROR "Unable to find libxml2 library")
  endif(NOT LIBXML2_FOUND)

  set(conky_libs ${conky_libs} ${LIBXML2_LIBRARIES})
  set(conky_includes ${conky_includes} ${LIBXML2_INCLUDE_DIR})
endif(WANT_LIBXML2)

# Look for doc generation programs
if(BUILD_DOCS)
  # Used for doc generation
  find_program(APP_PANDOC pandoc)

  if(NOT APP_PANDOC)
    message(FATAL_ERROR "Unable to find program 'pandoc'")
  endif(NOT APP_PANDOC)

  mark_as_advanced(APP_PANDOC)
endif(BUILD_DOCS)

if(BUILD_DOCS OR BUILD_EXTRAS)
  # Python3 with Jinja2 and PyYaml required for manpage generation.
  find_package(Python3 REQUIRED COMPONENTS Interpreter)
  execute_process(
    COMMAND ${Python3_EXECUTABLE} -c "import yaml"
    RESULT_VARIABLE EXIT_CODE
    OUTPUT_QUIET
  )

  if(NOT ${EXIT_CODE} EQUAL 0)
    message(
      FATAL_ERROR
      "The \"PyYAML\" Python3 package is not installed. Please install it using the following command: \"pip3 install pyyaml\"."
    )
  endif()

  execute_process(
    COMMAND ${Python3_EXECUTABLE} -c "import jinja2"
    RESULT_VARIABLE EXIT_CODE
    OUTPUT_QUIET
  )

  if(NOT ${EXIT_CODE} EQUAL 0)
    message(
      FATAL_ERROR
      "The \"Jinja2\" Python3 package is not installed. Please install it using the following command: \"pip3 install Jinja2\"."
    )
  endif()
endif(BUILD_DOCS OR BUILD_EXTRAS)

if(BUILD_COLOUR_NAME_MAP)
  find_program(APP_GPERF gperf)

  if(NOT APP_GPERF)
    message(FATAL_ERROR "Unable to find program 'gperf' (required at build-time as of Conky v1.20.2)")
  endif(NOT APP_GPERF)

  mark_as_advanced(APP_GPERF)
endif(BUILD_COLOUR_NAME_MAP)

if(CMAKE_BUILD_TYPE MATCHES "Debug")
  set(DEBUG true)
endif(CMAKE_BUILD_TYPE MATCHES "Debug")

# The version numbers are simply derived from the date and number of commits
# since start of month
if(DEBUG)
  execute_process(COMMAND ${APP_GIT} --git-dir=${CMAKE_CURRENT_SOURCE_DIR}/.git
    log --since=${VERSION_MAJOR}-${VERSION_MINOR}-01
    --pretty=oneline
    COMMAND ${APP_WC} -l
    COMMAND ${APP_AWK} "{print $1}"
    RESULT_VARIABLE RETVAL
    OUTPUT_VARIABLE COMMIT_COUNT
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif(DEBUG)
