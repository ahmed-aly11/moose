/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*           (c) 2010 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#include "BoundaryCondition.h"

#ifndef COUPLEDDIRICHLETBC_H
#define COUPLEDDIRICHLETBC_H

//Forward Declarations
class CoupledDirichletBC;

template<>
InputParameters validParams<CoupledDirichletBC>();

/**
 * Implements a coupled Dirichlet BC where u = value * some_var on the boundary.
 */
class CoupledDirichletBC : public BoundaryCondition
{
public:

  /**
   * Factory constructor, takes parameters so that all derived classes can be built using the same
   * constructor.
   */
  CoupledDirichletBC(const std::string & name, MooseSystem & moose_system, InputParameters parameters);
    
  virtual ~CoupledDirichletBC(){}

protected:
  virtual Real computeQpResidual();

private:
  /**
   * Multiplier on the boundary.
   */
  Real _value;

  /**
   * Holds the values at the quadrature points
   * of a coupled variable.
   */
  VariableValue & _some_var_val;
};

#endif //COUPLEDDIRICHLETBC_H
