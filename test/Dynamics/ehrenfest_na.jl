using Test
using NQCDynamics
using Statistics: var
using OrdinaryDiffEq: Vern9

kT = 9.5e-4
M = 30 # number of bath states
Γ = 6.4e-3
W = 6Γ / 2 # bandwidth  parameter

basemodel = MiaoSubotnik(;Γ)
bath = TrapezoidalRule(M, -W, W)
model = AndersonHolstein(basemodel, bath; fermi_level=0.001)
atoms = Atoms(2000)
r = randn(1,1)
v = randn(1,1)
n_electrons = M ÷ 2

@testset "Algorithm comparison: $method" for method in [:EhrenfestNA]
    sim = Simulation{eval(method)}(atoms, model)
    v = zeros(1,1)
    r = hcat(21.0)
    u = DynamicsVariables(sim, v, r)
    tspan = (0.0, 2000.0)
    dt = 10.0
    output = (OutputTotalEnergy, OutputKineticEnergy, OutputPotentialEnergy, OutputPosition, OutputVelocity, OutputQuantumSubsystem)
    traj1 = run_dynamics(sim, tspan, u; dt, output, algorithm=Vern9(), abstol=1e-15, reltol=1e-15, saveat=dt)
    @test isapprox(var(traj1[:OutputTotalEnergy]), 0; atol=1e-6)

    u = DynamicsVariables(sim, v, r)
    traj2 = run_dynamics(sim, tspan, u; dt, output) # default algorithm is fixed timestep
    @test isapprox(var(traj2[:OutputTotalEnergy]), 0; atol=1e-6)

    # Confirm all quantities are the same for the different algorithms
    @test traj1[:OutputKineticEnergy] ≈ traj2[:OutputKineticEnergy] rtol=1e-3
    @test traj1[:OutputPotentialEnergy] ≈ traj2[:OutputPotentialEnergy] rtol=1e-3
    @test traj1[:OutputVelocity] ≈ traj2[:OutputVelocity] rtol=1e-3
    @test traj1[:OutputPosition] ≈ traj2[:OutputPosition] rtol=1e-3
    @test traj1[:OutputQuantumSubsystem] ≈ traj2[:OutputQuantumSubsystem] rtol=1e-2
end

# sim = Simulation{EhrenfestNA}(atoms, model)
# v = zeros(1,1)
# r = hcat(21.0)
# u = DynamicsVariables(sim, v, r)
# @show Estimators.adiabatic_population(sim, u)
# tspan = (0.0, 10000.0)
# dt = 10.0
# output = (OutputTotalEnergy, OutputKineticEnergy, OutputPotentialEnergy, OutputPosition, OutputVelocity, OutputQuantumSubsystem, OutputAdiabaticPopulation)
# traj1 = run_dynamics(sim, tspan, u; dt, output)
# @test isapprox(var(traj1[:OutputTotalEnergy]), 0; atol=1e-6)

# sim = Simulation{EhrenfestNA2}(atoms, model)
# u = DynamicsVariables(sim, v, r)
# @show Estimators.adiabatic_population(sim, u)
# traj2 = run_dynamics(sim, tspan, u; dt, output)
# @test isapprox(var(traj2[:OutputTotalEnergy]), 0; atol=1e-6)

# sim = Simulation{Ehrenfest}(atoms, model)
# u = DynamicsVariables(sim, v, r, FermiDiracState(0.0, 0.0))
# @show Estimators.adiabatic_population(sim, u)
# traj4 = run_dynamics(sim, tspan, u; dt, output, algorithm=Vern9(), abstol=1e-10, reltol=1e-10)
# @test isapprox(var(traj4[:OutputTotalEnergy]), 0; atol=1e-6)

# using Plots
# p = plot(legend=true)
# plot!(traj1, :OutputTotalEnergy, label="1", legend=true)
# plot!(traj2, :OutputTotalEnergy, label="2", legend=true)
# # plot!(traj3, :OutputTotalEnergy, label="3", legend=true)
# plot!(traj4, :OutputTotalEnergy, label="4", legend=true)
# # plot!(traj1, :OutputPosition)
# # plot!(traj1, :OutputVelocity)
# # p2 = plot()
# # plot!([i[1] for i in traj1[:OutputQuantumSubsystem]])
# # plot!([i[1] for i in traj2[:OutputQuantumSubsystem]])

# # plot(p, p2, layout=(2,1), size=(600, 1000))
# # @test traj1[:OutputTotalEnergy] ≈ traj2[:OutputTotalEnergy]
# p
