using SBML_jll, Libdl

sbml = (sym::Symbol) -> dlsym(SBML_jll.libsbml_handle, sym)
const VPtr = Ptr{Cvoid}

sbmlfile = joinpath("src", "reactionsystem_02.xml")  # Point to any SBML file
doc = ccall(sbml(:readSBML), VPtr, (Cstring,), sbmlfile)

option = ccall(sbml(:ConversionOption_create), VPtr, (Cstring,), "promoteLocalParameters")
option = ccall(sbml(:ConversionOption_setType), VPtr, (VPtr, Cint), option, 0)
option = ccall(sbml(:ConversionOption_setValue), VPtr, (VPtr, Cint), option, 1)
option = ccall(sbml(:ConversionOption_setDescription), VPtr, (VPtr, Cstring), option, "Strip SBML Level 3 package constructs from the model")

props = ccall(sbml(:ConversionProperties_create), VPtr, ())
props = ccall(sbml(:ConversionProperties_addOption), VPtr, (VPtr, VPtr), props, option)

success = ccall(sbml(:SBMLDocument_convert), Cint, (VPtr,VPtr), doc, props)  # This is where the ReadOnlyMemoryError happens

n_errs = ccall(sbml(:SBMLDocument_getNumErrors), Cuint, (VPtr,), doc)
if n_errs > 0
    throw(AssertionError("Opening SBML document has reported errors"))
end
success