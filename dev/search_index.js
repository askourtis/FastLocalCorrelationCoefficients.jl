var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = FastLocalCorrelationCoefficients","category":"page"},{"location":"#FastLocalCorrelationCoefficients","page":"Home","title":"FastLocalCorrelationCoefficients","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for FastLocalCorrelationCoefficients.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Computing local correlation coefficients (also known as LCCs) is a basic step in various image-based data or information processing applications, including template or pattern matching, detection and estimation of motion or some other change in an image frame series, image registration from data collected at different times, projections, perspectives or with different acquisition modalities, and compression across multiple image frames.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The Fast Local Correlation Coefficients (FLCC) Library FastLocalCorrelationCoefficients.jl computes the Correlation Coefficients with Local Normalization for arbitrary dimensional tensors with real or complex values.","category":"page"},{"location":"","page":"Home","title":"Home","text":"For more information see:","category":"page"},{"location":"","page":"Home","title":"Home","text":"X. Sun, N. P. Pitsianis, and P. Bientinesi, Fast computation of local correlation coefficients, Proc. SPIE 7074, 707405 (2008)\nG. Papamakarios, G. Rizos, N. P. Pitsianis, and X. Sun, Fast computation of local correlation coefficients on graphics processing units, Proc. SPIE 7444, 744412 (2009)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [FastLocalCorrelationCoefficients]","category":"page"},{"location":"#FastLocalCorrelationCoefficients.flcc-Tuple{Any, Any}","page":"Home","title":"FastLocalCorrelationCoefficients.flcc","text":"  flcc(haystack,needle)\n\nCalculate the local correlation coefficients fast using fft.\n\nExample\n\nSuppose you have a haystack, a tensor of reals and a needle, a smaller tensor of the same dimensionality that you are are trying to locate in the haystack. Note that the needle might be scaled and translated.\n\nThe position of the maximum element of LCC is the best match between the needle and a sliding window of haystack\n\njulia> using FastLocalCorrelationCoefficients\n\njulia> haystack = rand(2^10,2^10);\n\njulia> needle = rand(1) .* haystack[42:48, 45:50] .+ rand(1);\n\njulia> LCC = flcc(haystack,needle);\n\njulia> argmax(LCC)\nCartesianIndex(42, 45)\n\n\n\n\n\n","category":"method"},{"location":"#FastLocalCorrelationCoefficients.flccComp-Tuple{Any, Any}","page":"Home","title":"FastLocalCorrelationCoefficients.flccComp","text":"Then, use the precomputed value tuple for every needle.\n\n  haystack = rand(2^20)\n  needle1 = rand(1) .* haystack[2:8] .+ rand(1)\n  needle2 = rand(1) .* haystack[42:48] .+ rand(1)\n  needle3 = rand(1) .* haystack[end-6:end] .+ rand(1)\n  precomp = FastLocalCorrelationCoefficients.flccPrec(haystack,size(needle1))\n  argmax(FastLocalCorrelationCoefficients.flccComp(precomp,needle1)) == 2\n  argmax(FastLocalCorrelationCoefficients.flccComp(precomp,needle2)) == 42\n  argmax(FastLocalCorrelationCoefficients.flccComp(precomp,needle3)) == 2^20-6\n\n\n\n\n\n","category":"method"},{"location":"#FastLocalCorrelationCoefficients.flccPrec-Tuple{Any, Any}","page":"Home","title":"FastLocalCorrelationCoefficients.flccPrec","text":"When you need to search for several needles of the same size, then you can avoid redundant computations by precomputing all common information.\n\n  haystack = rand(2^20)\n  needle1 = rand(1) .* haystack[2:8] .+ rand(1)\n  needle2 = rand(1) .* haystack[42:48] .+ rand(1)\n  needle3 = rand(1) .* haystack[end-6:end] .+ rand(1)\n  precomp = FastLocalCorrelationCoefficients.flccPrec(haystack,size(needle1))\n  argmax(FastLocalCorrelationCoefficients.flccComp(precomp,needle1)) == 2\n  argmax(FastLocalCorrelationCoefficients.flccComp(precomp,needle2)) == 42\n  argmax(FastLocalCorrelationCoefficients.flccComp(precomp,needle3)) == 2^20-6\n\n\n\n\n\n","category":"method"},{"location":"#FastLocalCorrelationCoefficients.lcc-Tuple{Any, Any}","page":"Home","title":"FastLocalCorrelationCoefficients.lcc","text":"  lcc(haystack,needle)\n\nCalculate the local correlation coefficients directly.\n\nExample\n\nSuppose you have a haystack, a tensor of reals and a needle, a smaller tensor of the same dimensionality that you are are trying to locate in the haystack. Note that the needle might be scaled and translated.\n\nThe position of the maximum element of LCC is the best match between the needle and a sliding window of haystack\n\njulia> using FastLocalCorrelationCoefficients\n\njulia> haystack = rand(2^10,2^10);\n\njulia> needle = rand(1) .* haystack[42:48, 45:50] .+ rand(1);\n\njulia> LCC = lcc(haystack,needle);\n\njulia> argmax(LCC)\nCartesianIndex(42, 45)\n\n\n\n\n\n","category":"method"}]
}
