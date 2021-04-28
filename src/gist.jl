
using SBML_jll, Libdl

sbml = (sym::Symbol) -> dlsym(SBML_jll.libsbml_handle, sym)
const VPtr = Ptr{Cvoid}

struct Retainer
    item
end

function readSBML(fn::String;conversion_options=Dict())
    doc = ccall(sbml(:readSBML), VPtr, (Cstring,), fn)
    r1 = Retainer(doc)
    try
        n_errs = ccall(sbml(:SBMLDocument_getNumErrors), Cuint, (VPtr,), doc)
        for i = 0:n_errs-1
            err = ccall(sbml(:SBMLDocument_getError), VPtr, (VPtr, Cuint), doc, i)
            # msg = get_string(err, :XMLError_getMessage)
            # @warn "SBML reported error: $msg"
        end
        if n_errs > 0
            throw(AssertionError("Opening SBML document has reported errors"))
        end

        if 0 == ccall(sbml(:SBMLDocument_isSetModel), Cint, (VPtr,), doc)
            throw(AssertionError("SBML document contains no model"))
        end

        for (k, v) in conversion_options
            props = ccall(sbml(:ConversionProperties_create), VPtr, ())
            r2 = Retainer(props)
            println(11)
            props = GC.@preserve props ccall(sbml(:ConversionProperties_addOption), VPtr, (Cstring,), k)
            println(props)
            println(1)
            if !(v==nothing)
                for (k1, v1) in v
                    props = ccall(sbml(:ConversionProperties_addOption), VPtr, (Cstring,Cstring), k1,v1)
                end
            end
            println(22)
            status = ccall(sbml(:SBMLDocument_convert), VPtr, (VPtr,), props)  # This is where the ReadOnlyMemoryError happens
        end
        println(33)
        model = ccall(sbml(:SBMLDocument_getModel), VPtr, (VPtr,), doc)
        println(44)

        return model  # extractModel(model)
    finally
        ccall(sbml(:SBMLDocument_free), Nothing, (VPtr,), doc)
    end
end

sbmlfile = joinpath(@__DIR__, "reactionsystem_01.xml")
readSBML(sbmlfile;conversion_options=Dict("replaceReactions"=>nothing))
