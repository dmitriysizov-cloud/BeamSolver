# BeamSolver

**BeamSolver** is a Wolfram Language package for analytical solution of
Euler–Bernoulli beam problems.

It determines support reactions and constructs analytical expressions for:

- shear force;
- bending moment;
- rotation angle;
- deflection.

Concentrated forces, concentrated moments, and uniformly distributed loads
can be combined in the same problem.

## Features

BeamSolver currently supports:

### Supports

- two simple supports (`"Pin"`, `"Pin"`);
- one fixed support (`"FixedEnd"`).

Supports may be located at arbitrary positions along the beam, so overhanging
beams are also supported.

### Loads

- concentrated transverse force;
- concentrated moment;
- uniformly distributed load over an arbitrary interval.

Multiple loads of different types may be combined.

### Output

The package provides:

- analytical support reactions;
- analytical shear-force function;
- analytical bending-moment function;
- analytical rotation-angle function;
- analytical deflection function;
- numerical substitution of parameter values;
- plots of all four beam quantities;
- determination of the value with the largest absolute magnitude and its
  position;
- direct use of the analytical solutions in interactive Wolfram Language
  constructs such as `Manipulate`.

A beam may be defined symbolically, with numerical values stored separately
under `"Numbers"`.

Because BeamSolver returns analytical expressions rather than only numerical
results at discrete points, the solution can be used directly in interactive
visualizations and animations. For example, the position of a moving load can
be treated as a parameter and varied with `Manipulate`, while the corresponding
beam deflection is updated immediately.


## Theoretical basis

BeamSolver is based on the linear Euler–Bernoulli theory for slender beams.
For a prismatic beam with constant Young's modulus \(E\) and second moment of
area \(J\), the transverse deflection \(v(x)\) satisfies

\[
EJ\,\frac{d^4 v}{dx^4}=p(x),
\]

where \(p(x)\) is the transverse loading, with signs defined according to the
convention used by BeamSolver.

The package uses a generalized-function formulation of the Euler–Bernoulli
beam equation. This formulation is closely related to the classical
singularity-function (Macaulay) method, but represents concentrated and
distributed loads explicitly using Dirac delta and Heaviside functions.

A point force \(P_i\) applied at \(x=a_i\), a concentrated moment \(M_i\)
applied at \(x=b_i\), and a uniform distributed load \(q_j\) acting from
\(x=c_j\) to \(x=d_j\) are represented, respectively, by

\[
P_i\,\delta(x-a_i),
\]

\[
-M_i\,\delta'(x-b_i),
\]

and

\[
q_j\left[H(x-c_j)-H(x-d_j)\right],
\]

where \(\delta\) is the Dirac delta function and \(H\) is the Heaviside step
function.

Support reactions are determined first from the equations of static
equilibrium and are then included in the same generalized loading function.
This makes it possible to describe a beam containing several loads of
different types by a single governing equation over the entire beam domain.

The governing equation is integrated analytically. For constant \(EJ\), the
resulting beam quantities are related by

\[
Q(x)=EJ\,v'''(x), \qquad
M(x)=EJ\,v''(x), \qquad
\theta(x)=v'(x),
\]

where \(Q(x)\), \(M(x)\), and \(\theta(x)\) are the shear force, bending
moment, and rotation angle, respectively. The four integration constants are
determined from the appropriate support and end boundary conditions.

Because Dirac delta and Heaviside functions have analytical primitives,
BeamSolver constructs a single closed-form solution without requiring the
beam to be manually divided into separate segments and the corresponding
piecewise solutions to be matched. Beam dimensions, load magnitudes, and load
positions can remain symbolic in the resulting expressions.

This symbolic formulation is particularly convenient for parametric and
interactive analysis. For example, the position of a concentrated load can
remain a symbolic parameter and then be varied with `Manipulate`, allowing the
corresponding beam deformation to be animated directly. A moving-load example
is included in `Examples/Usage examples.nb`.

## Repository structure

```text
BeamSolver/
├── PacletInfo.wl
├── README.md
├── LICENSE
├── CITATION.cff
├── .gitignore
├── Kernel/
│   └── BeamSolver.wl
└── Examples/
    └── Usage examples.nb
```

## Installation

### Recommended

Download `BeamSolver-1.0.0.paclet` from the latest GitHub Release.

Install it once in Wolfram Language / Mathematica:

```wl
PacletInstall["path/to/BeamSolver-1.0.0.paclet"]
```

Then load BeamSolver in any Mathematica session with:

```wl
Needs["BeamSolver`"]
```

The installation only needs to be performed once.

### From source

If you clone or download the repository source, you can load the repository
directory directly as a development paclet:

```wl
repo = "path/to/BeamSolver";
PacletDirectoryLoad[repo];
Needs["BeamSolver`"];
```

This method is mainly intended for development or inspection of the source
code. For normal use, installing the `.paclet` file from the latest GitHub
Release is recommended.

## Basic example

A simply supported beam of length `L` subjected to a central downward point
force `P` can be defined as

```wl
ClearAll[L, EE, J, P];

beam = <|
   "Supports" -> {
      <|"Type" -> "Pin", "x" -> 0|>,
      <|"Type" -> "Pin", "x" -> L|>
      },

   "Loadings" -> {
      <|
       "Type" -> "Force",
       "x" -> L/2,
       "Value" -> -P
       |>
      },

   "Length" -> L,
   "E" -> EE,
   "J" -> J,

   "Numbers" -> {
      L -> 4,
      EE -> 210 10^9,
      J -> 8 10^-6,
      P -> 10 10^3
      }
   |>;
```

Solve the beam analytically:

```wl
solution = beamSolve[beam];
```

Substitute the numerical values stored under `"Numbers"`:

```wl
solutionNumerical = beamPutValues[solution];
```

## Support reactions

```wl
beamReactions[solutionNumerical]
```

For the example above, the two vertical reactions are 5000 N.

## Accessing the solution

The beam fields are stored under `"Solutions"`:

```wl
solutionNumerical["Solutions"]["ShearForce"][x]
solutionNumerical["Solutions"]["BendingMoment"][x]
solutionNumerical["Solutions"]["RotationAngle"][x]
solutionNumerical["Solutions"]["Deflection"][x]
```

For example,

```wl
solutionNumerical["Solutions"]["Deflection"][2]
```

returns the midspan deflection.

## Maximum values

The signed value having the largest absolute magnitude and its position can be
found using

```wl
beamMaxValue[solutionNumerical, "BendingMoment"]
```

or

```wl
beamMaxValue[solutionNumerical, "Deflection"]
```

The search may be restricted to an interval:

```wl
beamMaxValue[solutionNumerical, "Deflection", {1, 3}]
```

Valid quantities are:

```text
"ShearForce"
"BendingMoment"
"RotationAngle"
"Deflection"
```

## Plots

```wl
beamPlots[solutionNumerical]
```

returns plots of shear force, bending moment, rotation angle, and deflection.

## Initial beam parameters

For configurations with an overhang, the rotation and deflection at the left
beam end can be obtained with

```wl
beamInitialParameters[solutionNumerical]
```

## Units

BeamSolver does not impose a unit system. Inputs must use a consistent system
of units.

For SI units:

- length: m;
- force: N;
- distributed load: N/m;
- moment: N m;
- Young's modulus: Pa;
- second moment of area: m^4;
- deflection: m.

## Sign convention

Loads are entered using signed `"Value"` fields.

A downward point force can be specified as

```wl
<|"Type" -> "Force", "x" -> a, "Value" -> -P|>
```

and a downward uniformly distributed load as

```wl
<|
 "Type" -> "Distributed",
 "x begin" -> a,
 "x end" -> b,
 "Value" -> -q
|>
```

## Examples

See `Examples/Usage examples.nb`.

The notebook contains eight analytical benchmark problems:

1. simply supported beam with a central point load;
2. simply supported beam with a uniformly distributed load;
3. cantilever with a tip force;
4. cantilever with a tip moment;
5. cantilever with a uniformly distributed load;
6. simply supported beam with an eccentric point load;
7. simply supported beam with a concentrated moment;
8. overhanging beam with a tip force.

It also contains a more general beam subjected to combined loading.

The notebook demonstrates how the analytical BeamSolver solution can be used
with `Manipulate` to animate the deformation of a beam as a concentrated load
moves along it.

## Validation

BeamSolver has been checked against closed-form Euler–Bernoulli beam solutions
for the eight benchmark cases listed above. The examples verify support
reactions, bending moments, deflections, and characteristic extrema.

## Current scope

BeamSolver is intended for statically determinate Euler–Bernoulli beam
problems covered by the support configurations listed above.

The current version does not model, among other effects:

- shear deformation;
- geometrically nonlinear deformation;
- material nonlinearity;
- dynamic response;
- elastic or multiple redundant supports.

## Requirements

- Wolfram Language / Mathematica
- BeamSolver paclet version 1.0.0

## Author

Dmitry Sizov  
Department of Mechanical and Aerospace Engineering  
Nazarbayev University

## Citation

If you use BeamSolver in academic work, please cite the software using the
metadata in `CITATION.cff`.

## License

BeamSolver is released under the MIT License. See `LICENSE`.
