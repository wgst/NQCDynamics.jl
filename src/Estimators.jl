
"""
    Estimators

Functions for computing thermal expectation values as ensemble averages.
"""
module Estimators

using NonadiabaticMolecularDynamics:
    AbstractSimulation,
    Simulation,
    RingPolymerSimulation,
    Calculators,
    DynamicsUtils,
    RingPolymers,
    ndofs,
    natoms,
    nbeads,
    masses,
    get_temperature

using StatsBase: mean
using ComponentArrays: ComponentVector

"""
    @estimate f(simulation, vector)

Evaluate `f(simulation, vector[i])` for all `i` and return the average.

Can be used for any function defined in `Estimators.jl`.
"""
macro estimate(expr)
    func = expr.args[1]
    sim = expr.args[2]
    configurations = expr.args[3]
    result, config = gensym(), gensym()

    return esc(quote
        local $result = 0
        for $config in $configurations
            $result += Estimators.$func($sim, $config)
        end
        $result / length($configurations)
    end)
end

function total_energy(sim::AbstractSimulation, u)
    kinetic_energy(sim, u) + potential_energy(sim, u)
end

function potential_energy(sim::AbstractSimulation, u)
    potential_energy(sim, DynamicsUtils.get_positions(u))
end

function potential_energy(sim::Simulation, r::AbstractMatrix)
    Calculators.evaluate_potential!(sim.calculator, r)
    sim.calculator.potential
end

function potential_energy(sim::RingPolymerSimulation, r::AbstractArray{T,3}) where {T}
    Calculators.evaluate_potential!(sim.calculator, r)
    mean(sim.calculator.potential)
end

function kinetic_energy(sim::Simulation, u)
    kinetic_energy(sim, DynamicsUtils.get_velocities(u))
end

function kinetic_energy(sim::Simulation, v::AbstractMatrix)
    DynamicsUtils.classical_kinetic_energy(sim, v)
end

function kinetic_energy(sim::RingPolymerSimulation, u)
    kinetic_energy(sim, DynamicsUtils.get_positions(u))
end

function kinetic_energy(sim::RingPolymerSimulation, r::AbstractArray{T,3}) where {T}
    centroid = RingPolymers.get_centroid(r)

    Calculators.evaluate_derivative!(sim.calculator, r)

    kinetic = ndofs(sim) * natoms(sim) * get_temperature(sim)

    for I in CartesianIndices(r)
        kinetic += (r[I] - centroid[I[1], I[2]]) * sim.calculator.derivative[I] 
    end

    return kinetic / 2nbeads(sim)
end

function diabatic_population end
function adiabatic_population end

end # module