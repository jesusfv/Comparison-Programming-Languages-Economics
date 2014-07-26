#
# Setup for innerloop_ext, which is an implementation of the innerloop using
# Cython in-place of Python
#
# Usage:
#     python setup.py build_ext --inplace
#
from distutils.core import setup
from distutils.extension import Extension

from Cython.Distutils import build_ext
import numpy


setup(
    cmdclass={'build_ext': build_ext},
    ext_modules=[Extension("innerloop_ext", ["innerloop_ext.pyx"])],
    include_dirs=[numpy.get_include()]
)