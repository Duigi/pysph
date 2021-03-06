# numpy
cimport numpy as np
cimport cython

from libcpp.map cimport map
from libcpp.vector cimport vector

import pyopencl as cl
import pyopencl.array

# PyZoltan CArrays
from pyzoltan.core.carray cimport UIntArray, IntArray, DoubleArray, LongArray

# local imports
from particle_array cimport ParticleArray
from point cimport *

from pysph.base.nnps_base cimport *

cdef extern from 'math.h':
    int abs(int) nogil
    double ceil(double) nogil
    double floor(double) nogil
    double fabs(double) nogil
    double fmax(double, double) nogil
    double fmin(double, double) nogil

cdef extern from 'limits.h':
    cdef unsigned int UINT_MAX
    cdef int INT_MAX

cdef inline copy_to_gpu(pa_wrapper, queue, dtype):
    if pa_wrapper.copied_to_gpu:
        return
    pa_wrapper.gpu_x = cl.array.to_device(queue, pa_wrapper.pa.x.astype(dtype))
    pa_wrapper.gpu_y = cl.array.to_device(queue, pa_wrapper.pa.y.astype(dtype))
    pa_wrapper.gpu_z = cl.array.to_device(queue, pa_wrapper.pa.z.astype(dtype))
    pa_wrapper.gpu_h = cl.array.to_device(queue, pa_wrapper.pa.h.astype(dtype))
    pa_wrapper.copied_to_gpu = True

cdef class GPUNeighborCache:
    cdef int _dst_index
    cdef int _src_index
    cdef int _narrays
    cdef list _particles

    cdef bint _cached
    cdef bint _copied_to_cpu
    cdef GPUNNPS _nnps

    cdef object _neighbors_gpu
    cdef object _nbr_lengths_gpu
    cdef object _start_idx_gpu

    cdef np.ndarray _neighbors_cpu
    cdef np.ndarray _nbr_lengths
    cdef np.ndarray _start_idx

    cdef unsigned int* _neighbors_cpu_ptr
    cdef unsigned int* _nbr_lengths_ptr
    cdef unsigned int* _start_idx_ptr

    cdef void copy_to_cpu(self)
    cdef void get_neighbors_raw(self, size_t d_idx, UIntArray nbrs)
    cdef void get_neighbors_raw_gpu(self)
    cpdef update(self)

    cdef void _find_neighbors(self)
    cpdef get_neighbors(self, int src_index, size_t d_idx, UIntArray nbrs)
    cpdef get_neighbors_gpu(self)

cdef class GPUNNPS(NNPSBase):

    cdef object ctx
    cdef object queue

    cdef public double radius_scale2
    cdef public GPUNeighborCache current_cache  # The current cache
    cdef public bint sort_gids        # Sort neighbors by their gids.

    cpdef get_nearest_particles(self, int src_index, int dst_index,
            size_t d_idx, UIntArray nbrs)

    cpdef get_nearest_particles_gpu(self, int src_index, int dst_index)

    cpdef get_spatially_ordered_indices(self, int pa_index, LongArray indices)

    cdef void get_nearest_neighbors(self, size_t d_idx, UIntArray nbrs)

    cdef void find_neighbor_lengths(self, nbr_lengths)

    cdef void find_nearest_neighbors_gpu(self, nbrs, start_indices)

    cpdef update(self)

    cpdef _bin(self, int pa_index)

    cpdef _refresh(self)

cdef class BruteForceNNPS(GPUNNPS):
    cdef NNPSParticleArrayWrapper src, dst # Current source and destination.
    cdef bint use_double
    cdef str preamble

    cpdef set_context(self, int src_index, int dst_index)

    cdef void find_neighbor_lengths(self, nbr_lengths)

    cdef void find_nearest_neighbors_gpu(self, nbrs, start_indices)

    cpdef _refresh(self)

