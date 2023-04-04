//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "MyFluid.h"
#include "SinglePhaseFluidProperties.h"


registerMooseObject("PorousFlowApp", MyFluid);
registerMooseObject("PorousFlowApp", ADMyFluid);

template <bool is_ad>
InputParameters
MyFluidTempl<is_ad>::validParams()
{
  InputParameters params = PorousFlowFluidPropertiesBaseTempl<is_ad>::validParams();
  params.addRequiredParam<UserObjectName>("fp", "The name of the user object for fluid properties");
  params.addParam<MaterialPropertyName>("viscosity1", "viscosity1", "dynamic viscosity (Pa.s)");
  params.addClassDescription("This Material calculates fluid properties at the quadpoints or nodes "
                             "for a single component fluid");
  return params;
}

template <bool is_ad>
MyFluidTempl<is_ad>::MyFluidTempl(
    const InputParameters & parameters)
  : PorousFlowFluidPropertiesBaseTempl<is_ad>(parameters),
    _fp(this->template getUserObject<SinglePhaseFluidProperties>("fp")),
    _viscosity1(this->template getMaterialProperty<Real>("viscosity1"))
{
}

template <bool is_ad>
void
MyFluidTempl<is_ad>::initQpStatefulProperties()
{
  if (_compute_rho_mu)
  {
    (*_density)[_qp] = _fp.rho_from_p_T(_porepressure[_qp][_phase_num] * _pressure_to_Pascals,
                                        _temperature[_qp] + _t_c2k);

    // (*_viscosity)[_qp] = _fp.mu_from_p_T(_porepressure[_qp][_phase_num] * _pressure_to_Pascals,
    //                                      _temperature[_qp] + _t_c2k) /
    //                      _pressure_to_Pascals / _time_to_seconds;
    (*_viscosity)[_qp] = _viscosity1[_qp];

  }

  if (_compute_internal_energy)
    (*_internal_energy)[_qp] = _fp.e_from_p_T(_porepressure[_qp][_phase_num] * _pressure_to_Pascals,
                                              _temperature[_qp] + _t_c2k);

  if (_compute_enthalpy)
    (*_enthalpy)[_qp] = _fp.h_from_p_T(_porepressure[_qp][_phase_num] * _pressure_to_Pascals,
                                       _temperature[_qp] + _t_c2k);
}

template <bool is_ad>
void
MyFluidTempl<is_ad>::computeQpProperties()
{
  if (_compute_rho_mu)
  {
    if (is_ad)
    {
      GenericReal<is_ad> rho, viscosity1;
      _fp.rho_mu_from_p_T(_porepressure[_qp][_phase_num] * _pressure_to_Pascals,
                          _temperature[_qp] + _t_c2k,
                          rho,
                          viscosity1);

      (*_density)[_qp] = rho;
      (*_viscosity)[_qp] = MetaPhysicL::raw_value(_viscosity1[_qp]);
    }
    else
    {
      // Density and viscosity, and derivatives wrt pressure and temperature
      Real rho, drho_dp, drho_dT, viscosity1, dmu_dp, dmu_dT;
      _fp.rho_mu_from_p_T(MetaPhysicL::raw_value(_porepressure[_qp][_phase_num]) *
                              _pressure_to_Pascals,
                          MetaPhysicL::raw_value(_temperature[_qp]) + _t_c2k,
                          rho,
                          drho_dp,
                          drho_dT,
                          viscosity1,
                          dmu_dp,
                          dmu_dT);
      (*_density)[_qp] = rho;
      (*_ddensity_dp)[_qp] = drho_dp * _pressure_to_Pascals;
      (*_ddensity_dT)[_qp] = drho_dT;
      (*_viscosity)[_qp] = MetaPhysicL::raw_value(_viscosity1[_qp]);
      (*_dviscosity_dp)[_qp] = MetaPhysicL::raw_value(_viscosity1[_qp]) / _time_to_seconds;
      (*_dviscosity_dT)[_qp] = MetaPhysicL::raw_value(_viscosity1[_qp]) / _pressure_to_Pascals / _time_to_seconds;
    }
  }
  
  if (_compute_internal_energy)
  {
    if (is_ad)
      (*_internal_energy)[_qp] = _fp.e_from_p_T(
          _porepressure[_qp][_phase_num] * _pressure_to_Pascals, _temperature[_qp] + _t_c2k);
    else
    {
      // Internal energy and derivatives wrt pressure and temperature at the qps
      Real e, de_dp, de_dT;
      _fp.e_from_p_T(MetaPhysicL::raw_value(_porepressure[_qp][_phase_num]) * _pressure_to_Pascals,
                     MetaPhysicL::raw_value(_temperature[_qp]) + _t_c2k,
                     e,
                     de_dp,
                     de_dT);
      (*_internal_energy)[_qp] = e;
      (*_dinternal_energy_dp)[_qp] = de_dp * _pressure_to_Pascals;
      (*_dinternal_energy_dT)[_qp] = de_dT;
    }
  }

  if (_compute_enthalpy)
  {
    if (is_ad)
      (*_enthalpy)[_qp] = _fp.h_from_p_T(_porepressure[_qp][_phase_num] * _pressure_to_Pascals,
                                         _temperature[_qp] + _t_c2k);
    else
    {
      // Enthalpy and derivatives wrt pressure and temperature at the qps
      Real h, dh_dp, dh_dT;
      _fp.h_from_p_T(MetaPhysicL::raw_value(_porepressure[_qp][_phase_num]) * _pressure_to_Pascals,
                     MetaPhysicL::raw_value(_temperature[_qp]) + _t_c2k,
                     h,
                     dh_dp,
                     dh_dT);
      (*_enthalpy)[_qp] = h;
      (*_denthalpy_dp)[_qp] = dh_dp * _pressure_to_Pascals;
      (*_denthalpy_dT)[_qp] = dh_dT;
    }
  }
}

template class MyFluidTempl<false>;
template class MyFluidTempl<true>;
