#
# Pattern example 1
#
# Phase changes driven by a combination mechanical (elastic) and chemical
# driving forces. In this three phase system a matrix phase, an oversized and
# an undersized precipitate phase compete. The chemical free energy favors a
# phase separation into either precipitate phase. A mix of both precipitate
# emerges to balance lattice expansion and contraction.
#
# This example demonstrates the use of
# * ACMultiInterface
# * SwitchingFunctionConstraintEta and SwitchingFunctionConstraintLagrange
# * DerivativeParsedMaterial
# * ElasticEnergyMaterial
# * DerivativeMultiPhaseMaterial
# * MultiPhaseStressMaterial
# which are the components to se up a phase field model with an arbitrary number
# of phases
#

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 80
  ny = 80
  nz = 0
  xmin = -20
  xmax = 20
  ymin = -20
  ymax = 20
  zmin = 0
  zmax = 0
  elem_type = QUAD4
[]

[GlobalParams]
  # CHParsed needs the third derivatives
  derivative_order = 3
  enable_jit = true
[]

# AuxVars to compute the free energy density for outputting
[AuxVariables]
  [./local_energy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./cross_energy]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./local_free_energy]
    type = TotalFreeEnergy
    variable = local_energy
    interfacial_vars = 'c'
    kappa_names = 'kappa_c'
    additional_free_energy = cross_energy
  [../]
  [./cross_terms]
    type = CrossTermGradientFreeEnergy
    variable = cross_energy
    interfacial_vars = 'eta1 eta2 eta3'
    kappa_names = 'kappa11 kappa12 kappa13
                   kappa21 kappa22 kappa23
                   kappa31 kappa32 kappa33'
  [../]
[]

[Variables]
  # Solute concentration variable
  [./c]
    order = FIRST
    family = LAGRANGE
    [./InitialCondition]
      type = RandomIC
      min = 0
      max = 0.8
      seed = 1235
    [../]
  [../]

  # Order parameter for the Matrix
  [./eta1]
    order = FIRST
    family = LAGRANGE
    initial_condition = 0.5
  [../]
  # Order parameters for the 2 different inclusion orientations
  [./eta2]
    order = FIRST
    family = LAGRANGE
    initial_condition = 0.1
  [../]
  [./eta3]
    order = FIRST
    family = LAGRANGE
    initial_condition = 0.1
  [../]

  # Mesh displacement
  [./disp_x]
    order = FIRST
    family = LAGRANGE
  [../]
  [./disp_y]
    order = FIRST
    family = LAGRANGE
  [../]

  # Lagrange-multiplier
  [./lambda]
    order = FIRST
    family = LAGRANGE
    initial_condition = 1.0
  [../]
[]

[Kernels]
  # Set up stress divergence kernels
  [./TensorMechanics]
    disp_x = disp_x
    disp_y = disp_y
  [../]

  # Cahn-Hilliard kernels
  [./c_res]
    type = CHParsed
    variable = c
    f_name = F
    args = 'eta1 eta2 eta3'
  [../]
  [./time]
    type = TimeDerivative
    variable = c
  [../]

  # Allen-Cahn and Lagrange-multiplier constraint kernels for order parameter 1
  [./deta1dt]
    type = TimeDerivative
    variable = eta1
  [../]
  [./ACBulk1]
    type = ACParsed
    variable = eta1
    args = 'eta2 eta3 c'
    mob_name = L1
    f_name = F
  [../]
  [./ACInterface1]
    type = ACMultiInterface
    variable = eta1
    etas = 'eta1 eta2 eta3'
    mob_name = L1
    kappa_names = 'kappa11 kappa12 kappa13'
  [../]
  [./lagrange1]
    type = SwitchingFunctionConstraintEta
    variable = eta1
    h_name   = h1
    lambda = lambda
  [../]

  # Allen-Cahn and Lagrange-multiplier constraint kernels for order parameter 2
  [./deta2dt]
    type = TimeDerivative
    variable = eta2
  [../]
  [./ACBulk2]
    type = ACParsed
    variable = eta2
    args = 'eta1 eta3 c'
    mob_name = L2
    f_name = F
  [../]
  [./ACInterface2]
    type = ACMultiInterface
    variable = eta2
    etas = 'eta1 eta2 eta3'
    mob_name = L2
    kappa_names = 'kappa21 kappa22 kappa23'
  [../]
  [./lagrange2]
    type = SwitchingFunctionConstraintEta
    variable = eta2
    h_name   = h2
    lambda = lambda
  [../]

  # Allen-Cahn and Lagrange-multiplier constraint kernels for order parameter 3
  [./deta3dt]
    type = TimeDerivative
    variable = eta3
  [../]
  [./ACBulk3]
    type = ACParsed
    variable = eta3
    args = 'eta1 eta2 c'
    mob_name = L3
    f_name = F
  [../]
  [./ACInterface3]
    type = ACMultiInterface
    variable = eta3
    etas = 'eta1 eta2 eta3'
    mob_name = L3
    kappa_names = 'kappa31 kappa32 kappa33'
  [../]
  [./lagrange3]
    type = SwitchingFunctionConstraintEta
    variable = eta3
    h_name   = h3
    lambda = lambda
  [../]

  # Lagrange-multiplier constraint kernel for lambda
  [./lagrange]
    type = SwitchingFunctionConstraintLagrange
    variable = lambda
    etas    = 'eta1 eta2 eta3'
    h_names = 'h1   h2   h3'
    epsilon = 1e-6
  [../]
[]

[Materials]
  # declare a few constants, such as mobilities (L,M) and interface gradient prefactors (kappa*)
  [./consts]
    type = GenericConstantMaterial
    block = 0
    prop_names  = 'M   kappa_c  L1 L2 L3  kappa11 kappa12 kappa13 kappa21 kappa22 kappa23 kappa31 kappa32 kappa33'
    prop_values = '0.2 0        1  1  1   2.00    2.00    2.00    2.00    2.00    2.00    2.00    2.00    2.00   '
  [../]

  # We use this to output the level of constraint enforcement
  # ideally it should be 0 everywhere, if teh constraint is fully enforced
  [./etasummat]
    type = ParsedMaterial
    block = 0
    f_name = etasum
    args = 'eta1 eta2 eta3'
    material_property_names = 'h1 h2 h3'
    function = 'h1+h2+h3-1'
    outputs = exodus
  [../]

  # This parsed material creates a single property for visualization purposes.
  # It will be 0 for phase 1, -1 for phase 2, and 1 for phase 3
  [./phasemap]
    type = ParsedMaterial
    block = 0
    f_name = phase
    args = 'eta2 eta3'
    function = 'if(eta3>0.5,1,0)-if(eta2>0.5,1,0)'
    outputs = exodus
  [../]

  # matrix phase
  [./eigenstrain_1]
    type = LinearElasticMaterial
    base_name = phase1
    block = 0
    disp_y = disp_y
    disp_x = disp_x
    # Stiffness tensor lambda, mu values
    C_ijkl = '3 3'
    fill_method = symmetric_isotropic
  [../]

  # oversized phase (simulated using thermal expansion)
  [./eigenstrain_2]
    type = LinearElasticMaterial
    base_name = phase2
    block = 0
    thermal_expansion_coeff = 0.02
    T0 = 0
    T = 1
    disp_y = disp_y
    disp_x = disp_x
    C_ijkl = '7 7'
    fill_method = symmetric_isotropic
  [../]

  # undersized phase (simulated using thermal expansion)
  [./eigenstrain_3]
    type = LinearElasticMaterial
    base_name = phase3
    block = 0
    thermal_expansion_coeff = -0.05
    T0 = 0
    T = 1
    disp_y = disp_y
    disp_x = disp_x
    C_ijkl = '7 7'
    fill_method = symmetric_isotropic
  [../]

  # switchiung functions
  [./switching1]
    type = SwitchingFunctionMaterial
    block = 0
    function_name = h1
    eta = eta1
    h_order = SIMPLE
  [../]
  [./switching2]
    type = SwitchingFunctionMaterial
    block = 0
    function_name = h2
    eta = eta2
    h_order = SIMPLE
  [../]
  [./switching3]
    type = SwitchingFunctionMaterial
    block = 0
    function_name = h3
    eta = eta3
    h_order = SIMPLE
  [../]

  [./barrier]
    type = MultiBarrierFunctionMaterial
    block = 0
    etas = 'eta1 eta2 eta3'
  [../]

  # chemical free energies
  [./chemical_free_energy_1]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fc1
    function = '4*c^2'
    args = 'c'
    derivative_order = 2
  [../]
  [./chemical_free_energy_2]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fc2
    function = '(c-0.9)^2-0.4'
    args = 'c'
    derivative_order = 2
  [../]
  [./chemical_free_energy_3]
    type = DerivativeParsedMaterial
    block = 0
    f_name = Fc3
    function = '(c-0.9)^2-0.5'
    args = 'c'
    derivative_order = 2
  [../]

  # elastic free energies
  [./elastic_free_energy_1]
    type = ElasticEnergyMaterial
    base_name = phase1
    f_name = Fe1
    block = 0
    derivative_order = 2
    args = 'c' # should be empty
  [../]
  [./elastic_free_energy_2]
    type = ElasticEnergyMaterial
    base_name = phase2
    f_name = Fe2
    block = 0
    derivative_order = 2
    args = 'c' # should be empty
  [../]
  [./elastic_free_energy_3]
    type = ElasticEnergyMaterial
    base_name = phase3
    f_name = Fe3
    block = 0
    derivative_order = 2
    args = 'c' # should be empty
  [../]

  # phase free energies (chemical + elastic)
  [./phase_free_energy_1]
    type = DerivativeSumMaterial
    block = 0
    f_name = F1
    sum_materials = 'Fc1 Fe1'
    args = 'c'
    derivative_order = 2
  [../]
  [./phase_free_energy_2]
    type = DerivativeSumMaterial
    block = 0
    f_name = F2
    sum_materials = 'Fc2 Fe2'
    args = 'c'
    derivative_order = 2
  [../]
  [./phase_free_energy_3]
    type = DerivativeSumMaterial
    block = 0
    f_name = F3
    sum_materials = 'Fc3 Fe3'
    args = 'c'
    derivative_order = 2
  [../]

  # global free energy
  [./free_energy]
    type = DerivativeMultiPhaseMaterial
    block = 0
    f_name = F
    fi_names = 'F1  F2  F3'
    hi_names = 'h1  h2  h3'
    etas     = 'eta1 eta2 eta3'
    args = 'c'
    W = 3
  [../]

  # Generate the global stress from the phase stresses
  [./global_stress]
    type = MultiPhaseStressMaterial
    block = 0
    phase_base = 'phase1 phase2 phase3'
    h          = 'h1     h2     h3'
  [../]
[]

[BCs]
  # the boundary conditions on the displacement enforce periodicity
  # at zero total shear and constant volume
  [./bottom_y]
    type = PresetBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  [../]
  [./top_y]
    type = PresetBC
    variable = disp_y
    boundary = 'top'
    value = 0
  [../]
  [./left_x]
    type = PresetBC
    variable = disp_x
    boundary = 'left'
    value = 0
  [../]
  [./right_x]
    type = PresetBC
    variable = disp_x
    boundary = 'right'
    value = 0
  [../]

  [./Periodic]
    [./disp_x]
      auto_direction = 'y'
    [../]
    [./disp_y]
      auto_direction = 'x'
    [../]

    # all other phase field vaiables are fully periodic
    [./c]
      auto_direction = 'x y'
    [../]
    [./eta1]
      auto_direction = 'x y'
    [../]
    [./eta2]
      auto_direction = 'x y'
    [../]
    [./eta3]
      auto_direction = 'x y'
    [../]
    [./lambda]
      auto_direction = 'x y'
    [../]
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

# We monitor the total free energy and teh total solute concentration (should be constant)
[Postprocessors]
  [./total_free_energy]
    type = ElementIntegralVariablePostprocessor
    variable = local_energy
  [../]
  [./total_solute]
    type = ElementIntegralVariablePostprocessor
    variable = c
  [../]
[]

[Executioner]
  type = Transient
  scheme = bdf2

  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type -sub_pc_type'
  petsc_options_value = 'asm      ilu'

  l_max_its = 30
  nl_max_its = 10
  l_tol = 1.0e-4
  nl_rel_tol = 1.0e-8
  nl_abs_tol = 1.0e-10
  start_time = 0.0
  num_steps = 200

  [./TimeStepper]
    type = SolutionTimeAdaptiveDT
    dt = 0.1
  [../]
[]

[Outputs]
  interval = 1
  exodus = true
  output_on = 'timestep_end'
  print_perf_log = true
  [./console]
    type = Console
    perf_log = true
    output_on = 'timestep_end failed nonlinear'
  [../]
  [./table]
    type = CSV
    delimiter = ' '
  [../]
[]

[Debug]
  # show_var_residual_norms = true
[]