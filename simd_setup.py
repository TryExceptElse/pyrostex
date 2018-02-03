########################################################################
#
#       FastNoiseSIMD setup file modified from that used by
#       PyFastNoiseSIMD, written by
#       Robert A. McLeod - robbmcleod@gmail.com
#       License: BSD
#       Created: August 13, 2017
#       C++ Library Author: Jordan Peck - https://github.com/Auburns
#
########################################################################


import platform
import os
import re
import subprocess as sub
import tempfile

from distutils.command.build_clib import build_clib
from distutils.ccompiler import new_compiler
from distutils.sysconfig import customize_compiler
from distutils.errors import CCompilerError, DistutilsOptionError, \
    DistutilsSetupError
from distutils import log

from settings import SIMD_NOISE_SOURCES


if os.name == 'nt':
    extra_cflags = []
    avx512 = {
        'sources': [
            SIMD_NOISE_SOURCES + '/FastNoiseSIMD_avx512.cpp'
        ],
        'cflags': [
            '/arch:AVX512',
        ],
    }
    avx2 = {
        'sources': [
            SIMD_NOISE_SOURCES + '/FastNoiseSIMD_avx2.cpp'
        ],
        'cflags': [
            '/arch:AVX2',
        ]
    }

    if platform.machine() == 'AMD64':  # 64-bit windows
        # `/arch:SSE2` doesn't exist on Windows x64 builds,
        # and generates needless warnings.
        sse41 = {
            'sources': [
                SIMD_NOISE_SOURCES + '/FastNoiseSIMD_sse41.cpp'
            ],
            'cflags': [
            ],
        }
        sse2 = {
            'sources': [
                SIMD_NOISE_SOURCES + '/FastNoiseSIMD_sse2.cpp'
            ],
            'cflags': [
            ],
        }
    else:  # 32-bit Windows
        sse41 = {
            'sources': [
                SIMD_NOISE_SOURCES + '/FastNoiseSIMD_sse41.cpp'
            ],
            'cflags': [
                '/arch:SSE2',
            ],
        }
        sse2 = {
            'sources': [
                SIMD_NOISE_SOURCES + '/FastNoiseSIMD_sse2.cpp'
            ],
            'cflags': [
                '/arch:SSE2',
            ],
        }
    fma_flags = None
else:  # Linux
    extra_cflags = ['-std=c++11']
    avx512 = {
        'sources': [
            SIMD_NOISE_SOURCES + '/FastNoiseSIMD_avx512.cpp'
        ],
        'cflags': [
            '-std=c++11',
            '-mavx512f',
        ],
    }
    avx2 = {
        'sources': [
            SIMD_NOISE_SOURCES + '/FastNoiseSIMD_avx2.cpp'
        ],
        'cflags': [
            '-march=core-avx2',
            '-std=c++11',
            '-mavx2',
        ]
    }
    sse41 = {
        'sources': [
            SIMD_NOISE_SOURCES + '/FastNoiseSIMD_sse41.cpp'
        ],
        'cflags': [
            '-std=c++11',
            '-msse4.1',
        ],
    }
    sse2 = {
        'sources': [
            SIMD_NOISE_SOURCES + '/FastNoiseSIMD_sse2.cpp'
        ],
        'cflags': [
            '-std=c++11',
            '-msse2',
        ],
    }
    fma_flags = ['-mfma']

c_libs = [
    ('avx512', avx512),
    ('avx2', avx2),
    ('sse41', sse41),
    ('sse2', sse2),
]


class BuildCLib(build_clib):
    user_options = build_clib.user_options + [
        ('with-avx512=', None, 'Use AVX512 instructions: auto|yes|no'),
        ('with-avx2=', None, 'Use AVX2 instructions: auto|yes|no'),
        ('with-sse41=', None, 'Use SSE4.1 instructions: auto|yes|no'),
        ('with-sse2=', None, 'Use SSE2 instructions: auto|yes|no'),
        ('with-fma=', None, 'Use FMA instructions: auto|yes|no'),
    ]

    def initialize_options(self):
        build_clib.initialize_options(self)
        self.with_avx512 = 'auto'
        self.with_avx2 = 'auto'
        self.with_sse41 = 'auto'
        self.with_sse2 = 'auto'
        self.with_fma = 'auto'

    def finalize_options(self):
        build_clib.finalize_options(self)

        compiler = new_compiler(compiler=self.compiler,
                                verbose=self.verbose)
        customize_compiler(compiler)

        disabled_libraries = []

        # Section for custom limits imposed on the SIMD instruction
        # levels based on the installed compiler
        plat_compiler = platform.python_compiler()
        if plat_compiler.lower().startswith('gcc'):
            log.info('gcc detected')
            # Check the installed gcc version, as versions older than
            # 7.0 claim to support avx512 but are missing some
            # intrinsics that FastNoiseSIMD calls.
            output = sub.check_output('gcc --version', shell=True)
            gcc_version = tuple([int(x) for x in
                                 re.findall(b'\d+(?:\.\d+)+', output)[
                                     0].split(b'.')])
            if gcc_version < (7, 2):  # Disable AVX512
                log.info('Disabled avx512; not supported with gcc < 7.2.')
                disabled_libraries.append('avx512')
            if gcc_version < (4, 7):  # Disable AVX2
                log.info('Disabled avx2; not supported with gcc < 4.7.')
                disabled_libraries.append('avx2')
        elif plat_compiler.lower().startswith('msc'):
            # No versions of Windows Python support AVX512 yet,
            # it is supported in MSVC2017 only.
            #                 MSVC++ 14.1 _MSC_VER == 1911 (Visual Studio 2017)
            #                 MSVC++ 14.1 _MSC_VER == 1910 (Visual Studio 2017)
            # Python 3.5/3.6: MSVC++ 14.0 _MSC_VER == 1900 (Visual Studio 2015)
            # Python 3.4:     MSVC++ 10.0 _MSC_VER == 1600 (Visual Studio 2010)
            # Python 2.7:     MSVC++ 9.0  _MSC_VER == 1500 (Visual Studio 2008)
            # Here we just assume the user has the platform compiler
            msc_version = int(
                re.findall('v\.\d+', plat_compiler)[0].lstrip('v.'))
            if msc_version < 1910:
                disabled_libraries.append('avx512')
            if msc_version < 1900:
                disabled_libraries.append('avx2')
        # End of SIMD limits

        for name, lib in self.distribution.libraries:
            val = getattr(self, 'with_' + name)
            if val not in ('auto', 'yes', 'no'):
                raise DistutilsOptionError(
                    'with_%s flag must be auto, yes, '
                    'or no, not "%s".' % (name, val))

            if val == 'no':
                disabled_libraries.append(name)
                continue

            if not self.compiler_has_flags(compiler, name, lib['cflags']):
                if val == 'yes':
                    # Explicitly required but not available.
                    raise CCompilerError('%s is not supported by your '
                                         'compiler.' % (name,))
                disabled_libraries.append(name)

        use_fma = False
        if (self.with_fma != 'no' and
                ('avx512' not in disabled_libraries or
                 'avx2' not in disabled_libraries)):
            if fma_flags is None:
                # No flags required.
                use_fma = True
            elif self.compiler_has_flags(compiler, 'fma', fma_flags):
                use_fma = True
                avx512['cflags'] += fma_flags
                avx2['cflags'] += fma_flags
            elif self.with_fma == 'yes':
                # Explicitly required but not available.
                raise CCompilerError(
                    'FMA is not supported by your compiler.')

        self.distribution.libraries = [lib
                                       for lib in
                                       self.distribution.libraries
                                       if lib[0] not in disabled_libraries]

        with open(SIMD_NOISE_SOURCES + '/x86_flags.h', 'wb') as fh:
            fh.write(b'// This file is generated by setup.py, '
                     b'do not edit it by hand\n')
            for name, lib in self.distribution.libraries:
                fh.write(b'#define FN_COMPILE_%b\n'
                         % (name.upper().encode('ascii', )))
            if use_fma:
                fh.write(b'#define FN_USE_FMA\n')

    def compiler_has_flags(self, compiler, name, flags):
        cwd = os.getcwd()
        with tempfile.TemporaryDirectory() as tmpdir:
            os.chdir(tmpdir)
            try:
                test_file = 'test-%s.cpp' % (name,)
                with open(test_file, 'w') as fd:
                    fd.write('int main(void) { return 0; }')

                try:
                    compiler.compile([test_file], extra_preargs=flags)
                except CCompilerError:
                    self.warn(
                        'Compiler does not support %s flags: %s' %
                        (name, ' '.join(flags)))
                    return False

            finally:
                os.chdir(cwd)

        return True

    # This method is extended from build_ext because the stock
    # implementation does not use passed 'cflags'.
    # The function is implemented here with these flags passed
    # as extra_postargs to the compiler.
    def build_libraries(self, libraries):
        for (lib_name, build_info) in libraries:
            sources = build_info.get('sources')
            if sources is None or not isinstance(sources, (list, tuple)):
                raise DistutilsSetupError(
                       "in 'libraries' option (library '%s'), "
                       "'sources' must be present and must be "
                       "a list of source filenames" % lib_name)
            sources = list(sources)

            log.info("building '%s' library", lib_name)

            # First, compile the source code to object files in the library
            # directory.  (This should probably change to putting object
            # files in a temporary build directory.)
            macros = build_info.get('macros')
            post_args = build_info.get('cflags')
            include_dirs = build_info.get('include_dirs')
            objects = self.compiler.compile(sources,
                                            extra_postargs=post_args,
                                            output_dir=self.build_temp,
                                            macros=macros,
                                            include_dirs=include_dirs,
                                            debug=self.debug)

            # Now "link" the object files together into a static library.
            # (On Unix at least, this isn't really linking -- it just
            # builds an archive.  Whatever.)
            self.compiler.create_static_lib(objects, lib_name,
                                            output_dir=self.build_clib,
                                            debug=self.debug)
