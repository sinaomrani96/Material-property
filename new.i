
[Mesh]
    [gen]
      type = GeneratedMeshGenerator
      dim = 2
      nx = 50
      xmin = 0
      xmax = 5
      ny = 50
      ymin = 0
      ymax = 5
    []
    [midleft]
      input = gen
      type = SubdomainBoundingBoxGenerator
      block_id = 1
      bottom_left = '0 3.5 0'
      top_right = '3.0 4.5 0'
    []
    [midright]
      input = midleft
      type = SubdomainBoundingBoxGenerator
      block_id = 2
      bottom_left = '2.0 1.0 0'
      top_right = '5.0 1.5 0'
    []  
    [rename]
      type = RenameBlockGenerator
      old_block = '0 1 2'
      new_block = '1 2 3'
      input = 'midright'
    []
  []

 
[GlobalParams]
  PorousFlowDictator = dictator
[]


[AuxVariables]

  [x00]
    order = CONSTANT
    family = MONOMIAL
  []
  [x01]
    order = CONSTANT
    family = MONOMIAL
  []

[]

[AuxKernels]

  [x00]
    type = PorousFlowPropertyAux
    variable = x00
    property = mass_fraction
    phase = 0
    fluid_component = 0
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

[]


[Variables]
  [porepressure]
    initial_condition = 20e6
  []
  [tracer_concentration]
    initial_condition = 0
  []
[]



[PorousFlowFullySaturated]
  porepressure = porepressure
  coupling_type = Hydro
  gravity = '0 -9.8 0'
  fp = tabulated_water
  mass_fraction_vars = tracer_concentration
  stabilization = Full # Note to reader: 06_KT.i uses KT stabilization - compare the results
[]

[BCs]
  [constant_injection_porepressure]
    type = PorousFlowSink
    variable = tracer_concentration
    flux_function = -1.74e-4
    boundary = left
  []
  [constant_outer_porepressure]
    type = DirichletBC
    variable = porepressure
    value = 20e6
    boundary = right
  []
  [outt]
    type = PorousFlowPiecewiseLinearSink
    variable = tracer_concentration
    boundary = right
    fluid_phase = 0
    pt_vals = '0 1E3 1E5 1E7 1E9'
    multipliers = '0 1E3 1E5 1E7 1E9'
    PT_shift = 1
    mass_fraction_component = 0
    use_mobility = true
    use_relperm = true
    flux_function = 10 # 1/L
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
[]

[Materials]
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
[]

[Preconditioning]
  active = basic
  [basic]
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = ' asm      lu           NONZERO                   2'
  []
  [preferred_but_might_not_be_installed]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
[]

[Debug]
  show_var_residual_norms = true
 # show_top_residuals = 2
 # show_execution_order = 'INITIAL TIMESTEP_BEGIN'
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = 150000
  nl_max_its = 40
  l_max_its = 40
  dtmax = 1800
  l_abs_tol = 1e-14
  nl_abs_tol = 1e-10
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
  []
  dtmin = 1
[]

[Outputs]
  exodus = true
[]

