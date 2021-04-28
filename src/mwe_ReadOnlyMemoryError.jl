using SBML_jll, Libdl

sbml = (sym::Symbol) -> dlsym(SBML_jll.libsbml_handle, sym)
const VPtr = Ptr{Cvoid}

sbmlfile = joinpath(@__DIR__, "reactionsystem_01.xml")  # Point to any SBML file
doc = ccall(sbml(:readSBML), VPtr, (Cstring,), sbmlfile)   
props = ccall(sbml(:ConversionProperties_create), VPtr, ())
props = ccall(sbml(:ConversionProperties_addOption), VPtr, (Cstring,), "replaceReactions")
status = ccall(sbml(:SBMLDocument_convert), VPtr, (VPtr,), props)  # ROME with `probs`, segfault with `doc`. Potentially we are using sbml_jll wrong?
