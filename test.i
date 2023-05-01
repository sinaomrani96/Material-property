
[Mesh]
  uniform_refine = 1
  [file]
    type = FileMeshGenerator
    file = new_out.e
    use_for_exodus_restart = true
  []
[]

[GlobalParams]
  PorousFlowDictator = 'dictator'
  gravity = '0 -9.8 0'
[]

[AuxVariables]
  [saturation_gas]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = 0
  []
  [x01]
    order = CONSTANT
    family = MONOMIAL
    initial_from_file_var = x01
  []
  [x10]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = 0
  []
  [x11]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = 0
  []
[]

[AuxKernels]
  [saturation_gas]
    type = PorousFlowPropertyAux
    variable = saturation_gas
    property = saturation
    phase = 1
    execute_on = 'timestep_end'
  []
  [x01]
    type = PorousFlowPropertyAux
    variable = x01
    property = mass_fraction
    phase = 0
    fluid_component = 1
    execute_on = 'timestep_end'
  []
  [x10]
    type = PorousFlowPropertyAux
    variable = x10
    property = mass_fraction
    phase = 1
    fluid_component = 0
    execute_on = 'timestep_end'
  []
  [x11]
    type = PorousFlowPropertyAux
    variable = x11
    property = mass_fraction
    phase = 1
    fluid_component = 1
    execute_on = 'timestep_end'
  []
[]

[Variables]
  [pwater]
    initial_from_file_var = porepressure
  []
  [satg]
    initial_condition = 0
  []
  [tracer]
    initial_from_file_var = tracer_concentration
    scaling = 1e-4
  []
[]

[Kernels]
  [mass0]
    type = PorousFlowMassTimeDerivative
    fluid_component = 1
    variable = pwater
  []
  [flux0]
    type = PorousFlowAdvectiveFlux
    fluid_component = 1
    variable = pwater
  []
  [mass1]
    type = PorousFlowMassTimeDerivative
    fluid_component = 0
    variable = tracer
  []
  [flux1]
    type = PorousFlowAdvectiveFlux
    fluid_component = 0
    variable = tracer
  []
  [mass2]
    type = PorousFlowMassTimeDerivative
    fluid_component = 2
    variable = satg
  []
  [flux2]
    type = PorousFlowAdvectiveFlux
    fluid_component = 2
    variable = satg
  []

[]

[UserObjects]
  [dictator]
    type = PorousFlowDictator
    porous_flow_vars = 'pwater tracer satg'
    number_fluid_phases = 2
    number_fluid_components = 3
  []
  [pc]
     type = PorousFlowCapillaryPressureBC
     lambda = 2.0
     pe = 1e4
    #type = PorousFlowCapillaryPressureConst
    #pc = 0
  []
[]

[FluidProperties]
  [true_water]
    type = Water97FluidProperties
  []
  [tabulated_water]
    type = TabulatedFluidProperties
    fp = true_water
    temperature_min = 275
    pressure_max = 1E8
    interpolated_properties = 'density viscosity enthalpy internal_energy'
    fluid_property_file = water97_tabulated_11.csv
  []
  [true_co2]
    type = CO2FluidProperties
  []
  [tabulated_co2]
    type = TabulatedFluidProperties
    fp = true_co2
    temperature_min = 275
    pressure_max = 1E8
    interpolated_properties = 'density viscosity enthalpy internal_energy'
    fluid_property_file = co2_tabulated_11.csv
  []
[]

[Materials]
  [temperature]
    type = PorousFlowTemperature
    temperature = '323'
  []
  [water]
    type = PorousFlowSingleComponentFluid
    fp = tabulated_water
    phase = 0
  []
  [co2]
    type = PorousFlowSingleComponentFluid
    fp = tabulated_co2
    phase = 1
  []
  [massfrac]
    type = PorousFlowMassFraction
    mass_fraction_vars = 'tracer x01 x10 x11'
  []
  [saturation_calculator]
    type = PorousFlow2PhasePS
    phase0_porepressure = pwater
    phase1_saturation = satg
    capillary_pressure = pc
  []
  [porosity]
    type = PorousFlowPorosity
    porosity_zero = 0.1
  []
  [permeability_aquifer]
    type = PorousFlowPermeabilityConst
    block = '2 3'
    permeability = '1E-13 0 0   0 1E-13 0   0 0 1E-13'
  []
  [permeability_caps]
    type = PorousFlowPermeabilityConst
    block = '1'
    permeability = '1E-15 0 0   0 1E-15 0   0 0 1E-16'
  []
  [relperm_water]
    type = PorousFlowRelativePermeabilityBC
    lambda = 2.0
    phase = 0
    s_res = 0.35
    sum_s_res = 0.4
    nw_phase = false
  []
  [relperm_gas]
    type = PorousFlowRelativePermeabilityBC
    lambda = 2.0
    nw_phase = true
    phase = 1
    s_res = 0.05
    sum_s_res = 0.4
  []
[]

[BCs]
  [injection]
    type = PorousFlowSink
    variable = satg
    flux_function = -3e-3
    boundary = 'left'
  []
  [outt]
    type = PorousFlowPiecewiseLinearSink
    variable = tracer
    boundary = right
    fluid_phase = 0
    pt_vals = '0 1E3 1E5 1E7 1E9'
    multipliers = '0 1E3 1E5 1E7 1E9'
    PT_shift = 1
    mass_fraction_component = 0
    use_mobility = false
    use_relperm = false
    flux_function = 10 # 1/L
  [] 
  [outp]
    type = PorousFlowPiecewiseLinearSink
    variable = pwater
    boundary = right
    fluid_phase = 0
    pt_vals = '0 1E3 1E5 1E7 1E9'
    multipliers = '0 1E3 1E5 1E7 1E9'
    PT_shift = 20e6
    mass_fraction_component = 1
    use_mobility = true
    use_relperm = true
    flux_function = 10 # 1/L
  [] 
[]

[Preconditioning]
  active = 'preferred'
  [basic]
    type = SMP
    full = true
    petsc_options = '-snes_converged_reason -ksp_diagonal_scale -ksp_diagonal_scale_fix -ksp_gmres_modifiedgramschmidt -snes_linesearch_monitor'
    petsc_options_iname = '-ksp_type -pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = 'gmres asm lu NONZERO 2'
  []
  [preferred]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = 'lu mumps'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = 150000
  nl_max_its = 40
  l_max_its = 40
  dtmax = 1800
  l_abs_tol = 1e-8
  nl_abs_tol = 1e-6
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
  []
  #dtmin = 1
[]

[Outputs]
  exodus = true
[]

[Debug]
  show_var_residual_norms = true
 # show_top_residuals = 2
 # show_execution_order = 'INITIAL TIMESTEP_BEGIN'
[]
