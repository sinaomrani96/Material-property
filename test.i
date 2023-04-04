# phase = 0 is liquid phase
# phase = 1 is gas phase
# fluid_component = 0 is water
# fluid_component = 1 is CO2

# Constant rate of CO2 injection into the left boundary
# 1D mesh
# The PorousFlowPiecewiseLinearSinks remove the correct water and CO2 from the right boundary

# Note i take pretty big timesteps here so the system is quite nonlinear
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 20
    xmin = 0
    xmax = 12
    ny = 20
    ymin = 0
    ymax = 6
  []
  [rightplugc]
    input = gen
    type = SubdomainBoundingBoxGenerator
    block_id = 1
    bottom_left = '6 0 0'
    top_right = '12 6 0'
  []

  [rename]
    type = RenameBlockGenerator
    old_block = '0 1'
    new_block = 'leftplug rightplug'
    input = rightplugc
  []
[]

[GlobalParams]
  PorousFlowDictator = dictator
  gravity = '0 -9.8 0'
[]

[AuxVariables]
  [saturation_gas1]
    order = CONSTANT
    family = MONOMIAL
  []
  [saturation_liq]
    order = CONSTANT
    family = MONOMIAL
  []
  [temperature]
    initial_condition = 323.00
  []
  [pressure1]
    initial_condition =  20e6
  []

  [frac_water_in_liquid]
    initial_condition = 1
  []
  [frac_water_in_gas]
    initial_condition = 0
  []
  [viscosity_liquid]
    order = FIRST
    family = MONOMIAL
  []
  [foo]
    order = CONSTANT
    family = MONOMIAL
    block = 'rightplug'
  []
[]

[AuxKernels]
  [saturation_gas1]
    type = PorousFlowPropertyAux
    variable = saturation_gas1
    property = saturation
    phase = 1
    execute_on = 'timestep_end'
  []
  [saturation_liq]
    type = PorousFlowPropertyAux
    variable = saturation_liq
    property = saturation
    phase = 0
    execute_on = 'timestep_end'
  []
  [viscosity_liquid]
    type = PorousFlowPropertyAux
    variable = viscosity_liquid
    property = viscosity
    phase = 0
    execute_on = 'timestep_end'
  []
  [copy_bar]
    type = MaterialRealAux
    property = LOL
    variable = foo
    execute_on = 'timestep_end'
  []
[]

[Variables]
  [pwater]
    initial_condition = 20e6
#	block = 'leftplug'
  []
  [sat1]
    initial_condition = 0
#	block = 'leftplug'
  []
[]

[Kernels]
  [mass0]
    type = PorousFlowMassTimeDerivative
    fluid_component = 0
    variable = pwater
	  block = 'leftplug rightplug'
  []
  [flux0]
    type = PorousFlowAdvectiveFlux
    fluid_component = 0
    variable = pwater
	  block = 'leftplug rightplug'
  []
  [mass1]
    type = PorousFlowMassTimeDerivative
    fluid_component = 1
    variable = sat1
	  block = 'leftplug rightplug'
  []
  [flux1]
    type = PorousFlowAdvectiveFlux
    fluid_component = 1
    variable = sat1
	  block = 'leftplug rightplug'
  []
[]

#[ICs]
##  [sat1]
 #   type = BoundingBoxIC
 #   variable = sat1
  #  x1 = 0
   # x2 = 6
    #y1 = 0
   # y2 = 6
   # inside = 0
   # outside = 0.9
  #[]
#[]

[Functions]
  [flux]
    type = ParsedFunction
    symbol_values = 'delta_xco2 dt'
    symbol_names = 'dx dt'
    expression = 'dx/dt'
  []

[]

[UserObjects]
  [dictator]
    type = PorousFlowDictator
    porous_flow_vars = 'pwater sat1'
    number_fluid_phases = 2
    number_fluid_components = 2
  []
  [pcl]
    type = PorousFlowCapillaryPressureBC
    lambda = 2
    pe = 1e4
#    pe = 0
    block = 'leftplug'
  []
  [pcr]
    type = PorousFlowCapillaryPressureBC
    lambda = 2
    pe = 1e4
    block = 'rightplug'
#    pe = 0
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
  [fp1]
    type = SimpleFluidProperties
    density0 = 1100
  []
[]

[Materials]
  [temperature]
    type = PorousFlowTemperature
    temperature = 323.15
  []
  [saturation_calculatorl]
    type = PorousFlow2PhasePS
    phase0_porepressure = pwater
    phase1_saturation = sat1
    capillary_pressure = pcl
    block = 'leftplug'
  []
  [saturation_calculatorr]
    type = PorousFlow2PhasePS
    phase0_porepressure = pwater
    phase1_saturation = sat1
    capillary_pressure = pcr
    block = 'rightplug'
  []
  [newvis]
    type = ParsedMaterial
    coupled_variables = 'sat1'
    block = 'rightplug'
    expression = '0.0004'
    # expression = '0.0004 + 0.01 * sat1'
    property_name = LO
    outputs = exodus
  []
  [massfrac]
    type = PorousFlowMassFraction
    mass_fraction_vars = 'frac_water_in_liquid frac_water_in_gas'
  []
  [waterl]
    type = PorousFlowSingleComponentFluid
    fp = tabulated_water
    phase = 0
    block = 'leftplug'
  []
  [waterr]
    type = MyFluid
    fp = fp1
    viscosity1 = LO
    phase = 0
    block = 'rightplug'
  []
  [co2]
    type = PorousFlowSingleComponentFluid
    fp = tabulated_co2
    phase = 1
  []
  [porosity]
    type = PorousFlowPorosityConst
    porosity = 0.2
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1e-12 0 0 0 1e-12 0 0 0 1e-12'
  []
  [relperm_water]
    type = PorousFlowRelativePermeabilityCorey
    n = 2
    phase = 0
    s_res = 0.1
    sum_s_res = 0.2
  []
  [relperm_gas]
    type = PorousFlowRelativePermeabilityBC
    nw_phase = true
    lambda = 2
    s_res = 0.1
    sum_s_res = 0.2
    phase = 1
  []
[]

[BCs]
  [co2_injection]
    type = PorousFlowSink
    boundary = left
    variable = sat1 # pgas is associated with the CO2 mass balance (fluid_component = 1 in its Kernels)   
    flux_function = -3E-3 # negative means a source, rather than a sink
  []

  [right_water]
    type = PorousFlowPiecewiseLinearSink
    boundary = right
    variable = pwater
    fluid_phase = 0
    pt_vals = '0 1E9'
    multipliers = '0 1E9'
    PT_shift = 20E6
    mass_fraction_component = 0
    use_mobility = true
    use_relperm = true
    flux_function = 10 # 1/L
  []

  [right_co2]
    type = PorousFlowPiecewiseLinearSink
    boundary = right
    variable = sat1
    fluid_phase = 1
    pt_vals = '0 1E9'
    multipliers = '0 1E9'
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
  end_time = 1500000
  nl_max_its = 40
  l_max_its = 30
  dtmax = 1800
  l_abs_tol = 1e-8
  nl_abs_tol = 1e-6
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
  []
  dtmin = 1
[]

[Postprocessors]
  # Postprocessors to get from the functions used as fluid properties
  [temperature]
    type = ElementAverageValue
    variable = temperature
    outputs = exodus
  []
  [pressure]
    type = ElementAverageValue
    variable = pressure1
    outputs = exodus
  []
  [saturation_gas2]
    type = ElementAverageValue
    variable = saturation_gas1
    block = 'rightplug'
  []
  [total_co2_in_gas]
    type = PorousFlowFluidMass
    phase = 1
    fluid_component = 1
  []
  [delta_xco2]
    type = ChangeOverTimePostprocessor
    postprocessor = total_co2_in_gas
  []
  [dt]
    type = TimestepSize
  []
  [flux]
    type = FunctionValuePostprocessor
    function = flux
  []
[]


[Outputs]
  print_linear_residuals = false
  perf_graph = true
  exodus = true 
  [out]
    type = CSV
    execute_on = 'FINAL'
  []
[]
