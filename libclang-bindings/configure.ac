AC_PREREQ([2.71])
AC_INIT([libclang-bindings],[0.1.0])

dnl --with-compiler argument: This argument is passed by Cabal, so we have to
dnl handle it.  We do not use it, so we ignore the passed value.
AC_ARG_WITH(
  [compiler],
  [AS_HELP_STRING([--with-compiler], [Haskell compiler])]
)

dnl --with-so argument: This argument allows users to specify the path to a
dnl shared library file, used to determine extra-libraries and extra-lib-dirs
dnl on Linux systems.  It is used to work around Cabal linking issues.
dnl
dnl If specified, $wt_user_lib_dir and $wt_user_lib are set.
wt_with_so_path='NOT_SET'
AC_ARG_WITH(
  [so],
  [AS_HELP_STRING([--with-so=PATH], [shared library to link to])],
  [wt_with_so_path=$withval],
  []
)
case "$wt_with_so_path" in
  /*)
    if test ! -f "$wt_with_so_path" ; then
      AC_MSG_ERROR([--with-so file not found: $wt_with_so_path])
    fi
    wt_user_lib_dir="$(dirname "$wt_with_so_path")"
    AC_MSG_NOTICE([with library directory: $wt_user_lib_dir])
    wt_with_so_filename="$(basename "$wt_with_so_path")"
    wt_with_so_lib_1="${wt_with_so_filename#lib}"
    if test "$wt_with_so_lib_1" = "$wt_with_so_filename" ; then
      AC_MSG_ERROR([--with-so file does not have lib prefix: $wt_with_so_path])
    fi
    wt_user_lib="${wt_with_so_lib_1%.so}"
    if test "$wt_user_lib" = "$wt_with_so_lib_1" ; then
      AC_MSG_ERROR([--with-so file does not have .so suffix: $wt_with_so_path])
    fi
    AC_MSG_NOTICE([with library: $wt_user_lib])
    ;;
  'NOT_SET')
    ;;
  '')
    AC_MSG_ERROR([--with-so specified without an argument])
    ;;
  *)
    AC_MSG_ERROR([--with-so path not absolute: $wt_with_so_path])
    ;;
esac

dnl LLVM_PATH variable: This argument allows users to specify the location of
dnl an LLVM installation, in which case llvm-config is not used.
AC_ARG_VAR(LLVM_PATH, [Location of LLVM installation])

dnl LLVM resolution:
dnl 1. Use LLVM_PATH if set
dnl 2. Use llvm-config in PATH if found
dnl 3. Fail if LLVM_PATH not set and llvm-config not in PATH
AC_MSG_CHECKING([LLVM resolution mode])
if test -n "$LLVM_PATH" ; then
  AC_MSG_RESULT([LLVM_PATH=$LLVM_PATH])
else
  AC_MSG_RESULT([llvm-config])
  AC_PATH_PROG([LLVM_CONFIG],[llvm-config],[])
  if test -z "$LLVM_CONFIG" ; then
    AC_MSG_ERROR([llvm-config not found and LLVM_PATH not set])
  fi
fi

dnl If using llvm-config, get the version.  This also checks that we can run
dnl llvm-config.
AC_MSG_CHECKING([llvm-config version])
if test -n "$LLVM_PATH" ; then
  AC_MSG_RESULT([skipped])
else
  wt_llvm_config_version="$("$LLVM_CONFIG" --version)"
  if test $? -eq 0 ; then
    AC_MSG_RESULT([$wt_llvm_config_version])
  else
    AC_MSG_RESULT([error])
    AC_MSG_ERROR([could not run llvm-config])
  fi
fi

# WT_PARSE_VERSION(VERSION_STRING)
#
# $wt_parse_version_status is set to 0 on success or 1 on failure
# $wt_parse_version_major is set to the major version on success
# $wt_parse_version_minor is set to the minor version on success
# $wt_parse_version_patch is set to the patch version on success
#
# NOTE This macro definition should not use dnl comments.
AC_DEFUN([WT_PARSE_VERSION], [
  wt_parse_version_major=''
  wt_parse_version_minor=''
  wt_parse_version_patch=''
  wt_parse_version_status=0 # SUCCESS
  wt_parse_version_input="$1"
  wt_parse_version_state=0 # STATE_START
  while test -n "$wt_parse_version_input" ; do
    wt_parse_version_tail="${wt_parse_version_input#?}"
    wt_parse_version_head="${wt_parse_version_input%${wt_parse_version_tail}}"
    wt_parse_version_input="$wt_parse_version_tail"
    case "$wt_parse_version_head" in
      0|1|2|3|4|5|6|7|8|9) # NOTE [0-9] does not work for some reason
        case "$wt_parse_version_state" in
          0) # STATE_START
            wt_parse_version_major="${wt_parse_version_head}"
            wt_parse_version_state=1 # STATE_MAJOR
            ;;
          1) # STATE_MAJOR
            wt_parse_version_major="${wt_parse_version_major}${wt_parse_version_head}"
            ;;
          2) # STATE_MAJOR_DOT
            wt_parse_version_minor="${wt_parse_version_head}"
            wt_parse_version_state=3 # STATE_MINOR
            ;;
          3) # STATE_MINOR
            wt_parse_version_minor="${wt_parse_version_minor}${wt_parse_version_head}"
            ;;
          4) # STATE_MINOR_DOT
            wt_parse_version_patch="${wt_parse_version_head}"
            wt_parse_version_state=5 # STATE_PATCH
            ;;
          5) # STATE_PATCH
            wt_parse_version_patch="${wt_parse_version_patch}${wt_parse_version_head}"
            ;;
        esac
        ;;
      .)
        case "$wt_parse_version_state" in
          1) # STATE_MAJOR
            wt_parse_version_state=2 # STATE_MAJOR_DOT
            ;;
          3) # STATE_MINOR
            wt_parse_version_state=4 # STATE_MINOR_DOT
            ;;
          5) # STATE_PATCH
            wt_parse_version_state=7 # STATE_SUCCESS
            break
            ;;
          *)
            wt_parse_version_state=6 # STATE_SKIP
            ;;
        esac
        ;;
      ' ')
        case "$wt_parse_version_state" in
          5) # STATE_PATCH
            wt_parse_version_state=7 # STATE_SUCCESS
            break
            ;;
          *)
            wt_parse_version_state=0 # STATE_START
            ;;
        esac
        ;;
      *)
        case "$wt_parse_version_state" in
          5) # STATE_PATCH
            wt_parse_version_state=7 # STATE_SUCCESS
            break
            ;;
          *)
            wt_parse_version_state=6 # STATE_SKIP
            ;;
        esac
        ;;
    esac
  done
  case "$wt_parse_version_state" in
    5|7) # STATE_PATCH STATE_SUCCESS
      ;;
    *)
      wt_parse_version_status=1 # FAILURE
      ;;
  esac
])

dnl Parse llvm-config version only if using llvm-config
if test -n "$wt_llvm_config_version" ; then
  AC_MSG_CHECKING([Parsing llvm-config version])
  WT_PARSE_VERSION([$wt_llvm_config_version])
  if test "$wt_parse_version_status" -eq 0 ; then
    wt_llvm_config_major="$wt_parse_version_major"
    wt_llvm_config_minor="$wt_parse_version_minor"
    wt_llvm_config_patch="$wt_parse_version_patch"
    AC_MSG_RESULT([major=$wt_llvm_config_major minor=$wt_llvm_config_minor patch=$wt_llvm_config_patch])
  else
    AC_MSG_RESULT([error])
    AC_MSG_ERROR([could not parse llvm-config version])
  fi
fi

dnl Clang library resolution:
dnl 1. Use user-specified library if --with-so is used
dnl 2. Use clang
AC_MSG_CHECKING([Clang library])
if test -n "$wt_user_lib" ; then
  wt_clang_lib="$wt_user_lib"
else
  wt_clang_lib='clang'
fi
AC_MSG_RESULT([$wt_clang_lib])
AC_SUBST([CLANG_LIB], ["$wt_clang_lib"])
dnl LIBS environment variable is set for checks below
LIBS="${LIBS} -l${wt_clang_lib}"

dnl LLVM library directory resolution:
dnl 1. Use llvm-config or LLVM_PATH to determine the real library directory
dnl 2. Append user-specified library directory if --with-so is used
AC_MSG_CHECKING([LLVM library directories])
if test -n "$LLVM_PATH" ; then
  wt_clang_lib_dirs="${LLVM_PATH}/lib"
else
  wt_clang_lib_dirs="$("$LLVM_CONFIG" --libdir)"
fi
dnl LDFLAGS environment variable is set for checks below
if test -n "$wt_user_lib_dir" && test "$wt_user_lib_dir" != "$wt_clang_lib_dirs"; then
  LDFLAGS="${LDFLAGS} -L${wt_user_lib_dir} -L${wt_clang_lib_dirs}"
  wt_clang_lib_dirs="${wt_user_lib_dir} ${wt_clang_lib_dirs}"
else
  LDFLAGS="${LDFLAGS} -L${wt_clang_lib_dirs}"
fi
AC_MSG_RESULT($wt_clang_lib_dirs)
AC_SUBST([CLANG_LIB_DIRS], ["$wt_clang_lib_dirs"])

dnl LLVM include directory resolution logic:
dnl 1. Use llvm-config or LLVM_PATH to determine the include directory
AC_MSG_CHECKING([LLVM include directory])
if test -n "$LLVM_PATH" ; then
  wt_clang_include_dir="${LLVM_PATH}/include"
else
  wt_clang_include_dir="$("$LLVM_CONFIG" --includedir)"
fi
dnl CPPFLAGS environment variable is set for checks below
CPPFLAGS="${CPPFLAGS} -I${wt_clang_include_dir}"
AC_MSG_RESULT($wt_clang_include_dir)
AC_SUBST([CLANG_INCLUDE_DIR], ["$wt_clang_include_dir"])

dnl Check C compiler needed for further checks
AC_PROG_CC

AC_CHECK_HEADER(
  [clang-c/Index.h],
  [],
  [AC_MSG_ERROR([Cannot find libclang headers])]
)

AC_CHECK_LIB(
  [$wt_clang_lib],
  [clang_createIndex],
  [],
  [AC_MSG_ERROR([Cannot link against libclang])]
)

dnl Get the version of the linked libclang shared library.  The version string
dnl is substituted into a generated Haskell module to provide the "compile-time"
dnl version.
AC_MSG_CHECKING([libclang version])
AC_LINK_IFELSE(
  [AC_LANG_PROGRAM(
    [[
      #include <clang-c/Index.h>
      #include <stdio.h>
    ]],
    [[
      CXString cxstring = clang_getClangVersion();
      printf("%s\n", clang_getCString(cxstring));
      clang_disposeString(cxstring);
    ]]
  )],
  [wt_libclang_version=$(./conftest$EXEEXT)],
  [AC_MSG_FAILURE([Unable to determine libclang version])]
)
AC_MSG_RESULT($wt_libclang_version)
AC_SUBST(
  [LIBCLANG_VERSION_STRING],
  ["$(echo ${wt_libclang_version} | sed 's/\"/\\\"/g')"]
)

dnl Parse libclang version
AC_MSG_CHECKING([Parsing libclang version])
WT_PARSE_VERSION([$wt_libclang_version])
if test "$wt_parse_version_status" -eq 0 ; then
  wt_libclang_major="$wt_parse_version_major"
  wt_libclang_minor="$wt_parse_version_minor"
  wt_libclang_patch="$wt_parse_version_patch"
  AC_MSG_RESULT([major=$wt_libclang_major minor=$wt_libclang_minor patch=$wt_libclang_patch])
  AC_SUBST([LIBCLANG_VERSION_MAJOR], [$wt_libclang_major])
  AC_SUBST([LIBCLANG_VERSION_MINOR], [$wt_libclang_minor])
  AC_SUBST([LIBCLANG_VERSION_PATCH], [$wt_libclang_patch])
else
  AC_MSG_RESULT([error])
  AC_MSG_ERROR([could not parse libclang version])
fi

dnl Check that libclang version matches llvm-config version when using
dnl llvm-config
if test -n "$wt_llvm_config_version" ; then
  if test "$wt_libclang_major" -ne "$wt_llvm_config_major" -o "$wt_libclang_minor" -ne "$wt_llvm_config_minor" -o "$wt_libclang_patch" -ne "$wt_llvm_config_patch" ; then
    AC_MSG_FAILURE([libclang and llvm-config versions do not match])
  fi
fi

dnl clang_isBeforeInTranslationUnit was introduced in Clang version 20.1, but
dnl CINDEX_VERSION_MINOR was not bumped, so we need to check for it.
AC_CHECK_FUNCS([clang_isBeforeInTranslationUnit])

dnl Output
AC_CONFIG_HEADERS([autogen/clang_config.h])
AC_CONFIG_FILES([
  libclang-bindings.buildinfo
  autogen/libclang_version.h
  autogen/Version_libclang_bindings.hs
])
AC_OUTPUT
