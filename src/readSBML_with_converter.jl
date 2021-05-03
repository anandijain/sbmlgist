using SBML_jll, Libdl, SBML

sbml = (sym::Symbol) -> dlsym(SBML_jll.libsbml_handle, sym)
const VPtr = Ptr{Cvoid}

"""
    function readSBML(fn::String)::Model

Read the SBML from a XML file in `fn` and return the contained `Model`.
"""
function readSBML(fn::String;conversion_options=Dict())::Model
    doc = ccall(sbml(:readSBML), VPtr, (Cstring,), fn)
    try
        n_errs = ccall(sbml(:SBMLDocument_getNumErrors), Cuint, (VPtr,), doc)
        for i = 0:n_errs-1
            err = ccall(sbml(:SBMLDocument_getError), VPtr, (VPtr, Cuint), doc, i)
            msg = get_string(err, :XMLError_getMessage)
            @warn "SBML reported error: $msg"
        end
        if n_errs > 0
            throw(AssertionError("Opening SBML document has reported errors"))
        end

        if 0 == ccall(sbml(:SBMLDocument_isSetModel), Cint, (VPtr,), doc)
            throw(AssertionError("SBML document contains no model"))
        end

        props = ccall(sbml(:ConversionProperties_create), VPtr, ())
        for (k, v) in conversion_options
            option = ccall(sbml(:ConversionOption_create), VPtr, (Cstring,), k)
            ccall(sbml(:ConversionProperties_addOption), Cvoid, (VPtr, VPtr), props, option)
            if !(v==nothing)
                for (vk, vv) in v
                    option = ccall(sbml(:ConversionOption_create), VPtr, (Cstring,), vk)
                    ccall(sbml(:ConversionOption_setValue), Cvoid, (VPtr, Cstring), option, vv)
                    ccall(sbml(:ConversionProperties_addOption), Cvoid, (VPtr, VPtr), props, option)
                end
            end
        end
        success = ccall(sbml(:SBMLDocument_convert), Cint, (VPtr,VPtr), doc, props)

        n_errs = ccall(sbml(:SBMLDocument_getNumErrors), Cuint, (VPtr,), doc)
        if n_errs > 0
            throw(AssertionError("Opening SBML document has reported errors"))
        end

        if success != 0  # @ Mirek: I think this should be `1` instead of `0`, right?
            throw(AssertionError("Conversion of SBML document failed"))
        end

        model = ccall(sbml(:SBMLDocument_getModel), VPtr, (VPtr,), doc)

        return SBML.extractModel(model) # Todo: remove `Sbml.`
    finally
        ccall(sbml(:SBMLDocument_free), Nothing, (VPtr,), doc)
    end
end

sbmlfile = joinpath("src", "reactionsystem_02.xml")  # Point to any SBML file

opts = Dict("promoteLocalParameters" => nothing)
model = readSBML(sbmlfile, conversion_options=opts)
println(model)

opts = Dict("stripPackage" => Dict("package" => "layout"))
model = readSBML(sbmlfile, conversion_options=opts)
println(model)