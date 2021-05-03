# This converter does not modify the xml file

using SBML_jll, Libdl

sbml = (sym::Symbol) -> dlsym(SBML_jll.libsbml_handle, sym)
const VPtr = Ptr{Cvoid}

sbmlfile = joinpath("src", "reactionsystem_02.xml")  # Point to any SBML file
doc = ccall(sbml(:readSBML), VPtr, (Cstring,), sbmlfile)   
props = ccall(sbml(:ConversionProperties_create), VPtr, ())
props = ccall(sbml(:ConversionProperties_addOptionWithKey), VPtr, (VPtr, Cstring), props, "promoteLocalParameters")
success = ccall(sbml(:SBMLDocument_convert), Cint, (VPtr,VPtr), doc, props)  # This is where the ReadOnlyMemoryError happens

n_errs = ccall(sbml(:SBMLDocument_getNumErrors), Cuint, (VPtr,), doc)
if n_errs > 0
    throw(AssertionError("Opening SBML document has reported errors"))
end
success

sbmlfile = joinpath("src", "converted.xml")
doc_c = ccall(sbml(:writeSBML), VPtr, (VPtr,Cstring), doc, sbmlfile)