using PyCall

cd(joinpath(Pkg.dir("LCMCore"), "deps", "builds", "lcm")) do
    if !isfile("CMakeCache.txt")
        error("LCMCore build not found. Try running 'Pkg.build(\"LCMCore\")'")
    end

    cachelines = open("CMakeCache.txt") do f
        readlines(f)
    end
    cmake_python_executable = nothing
    for line in cachelines
        m = match(r"PYTHON_EXECUTABLE(:[A-Z]*)?=(.*)", line)
        if m !== nothing
            cmake_python_executable = normpath(strip(m.captures[end]))
            break
        end
    end
    if cmake_python_executable != normpath(PyCall.pyprogramname)
        run(`cmake "-UPYTHON*" -DPYTHON_EXECUTABLE=$(normpath(PyCall.pyprogramname)) .`)
        run(`cmake --build . --target install`)
    end
end
