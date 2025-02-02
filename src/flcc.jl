
# Fast Local Correlation Coefficients
#
#

# when Frobenious norm too small, assume a constant tensor
tooSmall = 1e-13

@inline fcorr(x,y) = conv(x, reverse(y))

@inline norm(x) = sqrt(sum( i -> abs(i)^2, x) )

# NOTE: This overload removes CUDA.reverse `dims` keyword argument demand
# NOTE: This overload changes CUDA exports, consider overloading `fcorr`
function Base.reverse(A::AnyCuArray)
  d = ndims(A)
  d == 0 && return A

  # Reverse out-of-place
  R = reverse(A, dims=1)

  # Reverse in-place the rest of dimensions
  for k in 2:ndims(A)
    reverse!(R, dims=k)
  end

  # Return
  return R
end

@doc raw"""
```
  flcc(haystack,needle)
```
Calculate the local (Pearson) correlation coefficients

``\mathrm{lcc}(x,y) = \frac{(x - \mu_x)^T(y - \mu_y)}{\sigma_x \sigma_y}``

between `needle` and all sliding windows of same size within `haystack`.

`flcc` uses the fast Fourier
transform to reduce the computational complexity from O(``n_H n_N``) to
O((``n_H + n_N) log(n_H + n_N)``), where ``n_H`` and ``n_N`` are the number of
elements of the `haystack` and the `needle`, respectively.

`flcc` supports tensors of any dimensions with real or
complex entries.

# Examples

Suppose you have a `haystack`, a tensor of reals and a `needle`, a
smaller tensor of the same dimensionality that you are are trying to
locate in the `haystack`. Note that the `needle` might be scaled and
translated.

The position of the maximum element of `LCC` is the best match between
the `needle` and a sliding window of `haystack`

```jldoctest
julia> using FastLocalCorrelationCoefficients

julia> haystack = rand(2^10,2^10);

julia> needle = rand(1) .* haystack[42:48, 45:50] .+ rand(1);

julia> c = flcc(haystack,needle);

julia> best_correlated(c)
CartesianIndex(42, 45)
```

When you need to search for many needles of the same size,

```
  haystack = rand(2^20);
  needle1 = rand(1) .* haystack[2:8] .+ rand(1);
  needle2 = rand(1) .* haystack[42:48] .+ rand(1);
  needle3 = rand(1) .* haystack[end-6:end] .+ rand(1);
```
you can preprocess the `haystack` to avoid redundant computations by
precomputing all common information. There is no such preprocessing
when using the direct method.
```
  precomp = flcc(haystack,size(needle1));

```
Then use it for much faster queries.
```
  best_correlated(flcc(precomp,needle1)) == 2
  best_correlated(flcc(precomp,needle2)) == 42
  best_correlated(flcc(precomp,needle3)) == 2^20-6
```

"""
function flcc(F::AbstractArray,T::AbstractArray)

  return flcc(flcc(F,size(T)),T)

end

# precompute
function flcc(F::AbstractArray,nT::Tuple)

  nF = size(F)
  pF = prod(nF)
  pT = prod(nT)

  nM = nF .+ nT .- 1

  # Allocate similar temporary to preserve eltype and array type
  T = similar(F, eltype(F), nT)

  T .= 1/sqrt(pT)
  μ = abs.(conv(F, T)) .^ 2

  T .= 1
  σ̅ = sqrt.(conv(abs.(F) .^ 2, T) .- μ)

  return FLCC_precomp(F, nF, nT, pT, σ̅)
end

# TODO: `FLCC_precomp` does not have a handle for the distributed case
function flcc(F::DArray, T::AbstractArray; cuda::Bool=false)

  # Import flcc to all workers
  @everywhere F.pids @eval import FastLocalCorrelationCoefficients: flcc

  # Allocate result array
  R = dzeros(eltype(F), size(F) .- size(T) .+ 1, F.pids, size(F.indices))

  # For each worker do work or skip if not in `F.pids`
  @sync @distributed for _ = 1:nworkers()
    iR = localindices(R)
    if !any(isempty.(iR))
      fiR = first.(iR)
      liR = last.(iR)

      # Local indices of F
      # NOTE: It is not guaranteed by the `DistributedArrays.jl` documentation that `F` and `R` are distributed the same way.
      #       This may lead to overhead due to data transfer
      iF = (:).(fiR, liR .+ size(T) .- 1)

      # Extract local parts
      pF = @inbounds @view F[iF...]
      pR = localpart(R)

      pR .= cuda ? Array(flcc(CuArray(pF), CuArray(T))) : flcc(Array(pF), T)
    end
  end

  return R
end

# apply precomputation
function flcc(prec::FLCC_precomp, Tin::AbstractArray)

  F, nF, nT, pT, σ̅ = [getproperty(prec,i) for i in fieldnames(FLCC_precomp) ]

  T = copy( Tin )
  T .= T .- sum(T)/pT

  normT = norm(T)
  if normT > tooSmall
    T .= T ./ normT
  else
    error("This method does not support searches for constant segments!")
  end

  M = fcorr(F, conj(T) .- sum(T)) ./ σ̅

  # restrict to valid
  return M[CartesianIndex((nT)):CartesianIndex(nF)] |> ( (eltype(F)<:Real) ? real : (x -> x) )
end

"""
```
  best_correlated(c::AbstractArray)
```
Locate the position of the element with the maximum local correlation value.
"""
function best_correlated(M::AbstractArray)
  return argmax(( eltype(M) <: Complex ) ? abs.(M) : M)
end

# Direct for debugging

"""
```
  lcc(haystack,needle)
```
Calculate the local (Pearson) correlation coefficients between a
`needle` and a sliding window within `haystack`, directly.

# Example

Suppose you have a `haystack`, a tensor of reals and a `needle`, a
smaller tensor of the same dimensionality that you are are trying to
locate in the `haystack`. Note that the `needle` might be scaled and
translated.

The position of the maximum LCC is the best match between
the `needle` and a sliding window of `haystack`

```jldoctest
julia> using FastLocalCorrelationCoefficients

julia> haystack = rand(2^10,2^10);

julia> needle = rand(1) .* haystack[42:47, 45:50] .+ rand(1);

julia> c = lcc(haystack,needle);

julia> best_correlated(c)
CartesianIndex(42, 45)
```
"""
function lcc(F,Tin)

  T = copy( Tin )

  nF = size(F); pF = prod(nF)
  nT = size(T); pT = prod(nT)

  T .= T .- sum(T)/pT

  normT = norm(T)
  if normT > tooSmall
    T .= T ./ normT
  else
    error("This method does not support searches for constant segments!")
  end

  M = zeros(eltype(F), nF .- nT .+ 1)

  # pattern from # https://julialang.org/blog/2016/02/iteration/
  R  = CartesianIndices(M)
  Is = CartesianIndex( nT.-1 )

  w = zeros( eltype(T), nT )

  @inbounds @simd for I ∈ R

    w .= @view F[I : (I+Is)]
    w .-= sum(w)/pT

    M[I] = dot( T, w ) / norm(w)
  end

  return M

end

