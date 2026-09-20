(* ::Package:: *)

(* ::Input::Initialization:: *)
BeginPackage["BeamSolver`"];


(* ::Input::Initialization:: *)
beamSolve::usage="beamSolve[beam] solves the specified Euler-Bernoulli beam problem.";

beamPutValues::usage="beamPutValues[beam] substitutes the numerical parameter values stored under \"Numbers\".";

beamReactions::usage="beamReactions[solution] returns the support reactions.";

beamPlots::usage="beamPlots[solution] plots shear force, bending moment, rotation angle, and deflection.";

beamMaxValue::usage="beamMaxValue[solution, quantity] returns the value with the largest absolute magnitude and its position. Valid quantities are \"ShearForce\", \"BendingMoment\", \"RotationAngle\", and \"Deflection\". beamMaxValue[solution, quantity, {xmin, xmax}] restricts the search to the specified interval.";

beamInitialParameters::usage="beamInitialParameters[solution] returns the initial rotation angle and deflection.";


(* ::Input::Initialization:: *)
Begin["`Private`"];


(* ::Input::Initialization:: *)
vector3dQ[arg_List]:=Length@arg==3
vector3dQ[___]:=False


(* ::Input::Initialization:: *)
moment[{r_?vector3dQ,force_?vector3dQ}]:=(r\[Cross]force)

zmoment[{r_?vector3dQ,force_?vector3dQ}]:=moment[{r,force}][[3]]

zmoment[input:{{_?vector3dQ,_?vector3dQ}..}]:=Total[(zmoment/@input)]

zmoment[input:{{_?vector3dQ,_?vector3dQ}..},Optional[zmoments:{___},{}]]:=Total[(zmoment/@input)~Join~zmoments]


(* ::Input::Initialization:: *)
radiusVectors[center_?vector3dQ,points:{_?vector3dQ..}]:=#-center&/@points


(* ::Input::Initialization:: *)
zmomentEquation[
centers:{__?vector3dQ},
forces:{__?vector3dQ},
applicationpoints:{__?vector3dQ},
Optional[moments:{___},{}]]:=
zmoment[Transpose[{#,forces}],moments]==0&/@(radiusVectors[#,applicationpoints]&/@centers)

zmomentEquation[
centers:{__?vector3dQ},forcespoints:{{(*force*)_?vector3dQ,(*application point*)_?vector3dQ}..},
Optional[moments:{___},{}]]:=zmomentEquation[centers,##,moments]&@@Transpose[forcespoints]


(* ::Input::Initialization:: *)
axisOrts["x"]:={1,0,0}
axisOrts["y"]:={0,1,0}
axisOrts["z"]:={0,0,1}


(* ::Input::Initialization:: *)
axisNameQ[name:"x"|"y"|"z"]:=True
axisNameQ[___]:=False


(* ::Input::Initialization:: *)
projectionEquation[orts:{__?vector3dQ},forces:{__?vector3dQ}]:=Total[#]==0&/@Outer[Dot,orts,forces,1]

projectionEquation[axisname:{__?axisNameQ},forces:{__?vector3dQ}]:=projectionEquation[axisOrts/@axisname,forces]


(* ::Input::Initialization:: *)
momentAboutAxis[axis_?vector3dQ,moment_?vector3dQ]:=moment . axis/Norm[axis]
momentAboutAxis[
axis_?axisNameQ,
axesOrigin_?vector3dQ,
forces:{__?vector3dQ},
applicationpoints:{__?vector3dQ},
Optional[moments_,{}]]:=momentAboutAxis[
axisOrts[axis],axesOrigin,forces,applicationpoints,moments]

momentAboutAxis[
axes:{_?axisNameQ..},
axesOrigin_?vector3dQ,
forces:{__?vector3dQ},
applicationpoints:{__?vector3dQ},
Optional[moments_,{}]]:=momentAboutAxis[
axisOrts[#],axesOrigin,forces,applicationpoints,moments]&/@axes

momentAboutAxis[
axis_?vector3dQ,
axesOrigin_?vector3dQ,
forces:{__?vector3dQ},
applicationpoints:{__?vector3dQ},
Optional[moments_,{}]]:=
momentAboutAxis[axis,
Total[
(moment/@Transpose[{radiusVectors[axesOrigin,applicationpoints],forces}])~Join~moments
]]


(* ::Input::Initialization:: *)
momentAboutAxisEquation[
axes:{_?vector3dQ..},
axesOrigin_?vector3dQ,
forces:{__?vector3dQ},
applicationpoints:{__?vector3dQ},
Optional[moments_,{}]]:=momentAboutAxis[
#,axesOrigin,forces,applicationpoints,moments]==0&/@axes

momentAboutAxisEquation[
axes:{_?axisNameQ..},
axesOrigin_?vector3dQ,
forces:{__?vector3dQ},
applicationpoints:{__?vector3dQ},
Optional[moments_,{}]]:=momentAboutAxisEquation[
axisOrts/@axes,axesOrigin,forces,applicationpoints,moments]


(* ::Input::Initialization:: *)
noNullInsideQ[arg_]:=FreeQ[arg,Null]


forceQ[arg_Association]:=Lookup[arg,"Type",None]==="Force"&&ContainsAll[Keys[arg],{"Type","x","Value"}]&&noNullInsideQ[arg]

forceQ[___]:=False


momentQ[arg_Association]:=Lookup[arg,"Type",None]==="Moment"&&ContainsAll[Keys[arg],{"Type","x","Value"}]&&noNullInsideQ[arg]

momentQ[___]:=False


distributedQ[arg_Association]:=Lookup[arg,"Type",None]==="Distributed"&&ContainsAll[Keys[arg],{"Type","x begin","x end","Value"}]&&noNullInsideQ[arg]

distributedQ[___]:=False


loadingQ[arg_Association]:=forceQ[arg]||momentQ[arg]||distributedQ[arg]

loadingQ[___]:=False


(* ::Input::Initialization:: *)
supportQ[arg_Association]:=ContainsAll[Keys[arg],{"Type","x"}]&&MatchQ[arg["Type"],"Pin"|"FixedEnd"]

supportQ[___]:=False


(* ::Input::Initialization:: *)
loadingListQ[arg_List]:=AllTrue[arg,loadingQ]
loadingListQ[___]:=False

supportListQ[arg_List]:=arg=!={}&&AllTrue[arg,supportQ]

supportListQ[___]:=False


beamQ[arg_Association]:=ContainsAll[Keys[arg],{"Supports","Loadings","Length","E","J"}]&&loadingListQ[arg["Loadings"]]&&supportListQ[arg["Supports"]]

beamQ[___]:=False


(* ::Input::Initialization:: *)
beamPutValues[beam_?beamQ]:=Module[{hThetaRules,values},hThetaRules={HeavisideTheta[0]->1,HeavisideTheta[0.]->1};
values=Lookup[beam,"Numbers",{}];
Map[Evaluate,Map[#/. values/. hThetaRules&,KeyDrop[beam,"Numbers"]],Infinity]/. hThetaRules]


(* ::Input::Initialization:: *)
pinQ[beam_?beamQ]:=#["Type"]&/@beam["Supports"]==={"Pin","Pin"}
pinQ[___]:=False


(* ::Input::Initialization:: *)
fixedEndQ[beam_?beamQ]:=#["Type"]&/@beam["Supports"]==={"FixedEnd"}
fixedEndQ[___]:=False


(* ::Input::Initialization:: *)
resultantOfDistributed[arg_?distributedQ]:=<|"Type"->"Force","x"->(arg["x end"]+arg["x begin"])/2,"Value"->arg["Value"] (arg["x end"]-arg["x begin"])|>

resultantOfDistributed[arg_]:=arg


(* ::Input::Initialization:: *)
convertForcesForStaticEquilibrium[loads_List]:=Function[arg,{{0,arg["Value"],0},{arg["x"],0,0}}]/@Map[resultantOfDistributed,Cases[loads,_?(forceQ[#]||distributedQ[#]&)]]


(* ::Input::Initialization:: *)
convertMomentsForStaticEquilibrium[loads_List]:=#["Value"]&/@Cases[loads,_?momentQ]


(* ::Input::Initialization:: *)
momentPoints[beam_?beamQ]:={{0,0,0},{beam["Length"],0,0}}


(* ::Input::Initialization:: *)
findReactions[beam_?pinQ]:=Module[{yA,yB,eqs,sol},eqs=zmomentEquation[momentPoints[beam],Join[convertForcesForStaticEquilibrium[beam["Loadings"]],{{{0,yA,0},{beam["Supports"][[1]]["x"],0,0}},{{0,yB,0},{beam["Supports"][[2]]["x"],0,0}}}],convertMomentsForStaticEquilibrium[beam["Loadings"]]];
sol=Quiet@Check[Solve[eqs,{yA,yB}],$Failed];
If[sol===$Failed||sol==={},$Failed,{yA,yB}/. First[sol]]]

findReactions[beam_?fixedEndQ]:=Module[{Y,M,forces,eqs,sol,xSupport},xSupport=beam["Supports"][[1]]["x"];
forces=Join[convertForcesForStaticEquilibrium[beam["Loadings"]],{{{0,Y,0},{xSupport,0,0}}}];
eqs=Join[zmomentEquation[{{xSupport,0,0}},forces,Join[convertMomentsForStaticEquilibrium[beam["Loadings"]],{M}]],projectionEquation[{"y"},forces[[All,1]]]];
sol=Quiet@Check[Solve[eqs,{Y,M}],$Failed];
If[sol===$Failed||sol==={},$Failed,{Y,M}/. First[sol]]]


(* ::Input::Initialization:: *)
convertReactionsForBeam[beam_?pinQ]:=Module[{reactions},reactions=findReactions[beam];
If[reactions===$Failed,Return[$Failed]];
MapThread[<|"Type"->"Force","x"->#1,"Value"->#2,"Kind"->"Reaction"|>&,{#["x"]&/@beam["Supports"],reactions}]]

convertReactionsForBeam[beam_?fixedEndQ]:=Module[{reactions,Y,M,xSupport},reactions=findReactions[beam];
If[reactions===$Failed,Return[$Failed]];
{Y,M}=reactions;
xSupport=beam["Supports"][[1]]["x"];
{<|"Type"->"Force","x"->xSupport,"Value"->Y,"Kind"->"Reaction"|>,<|"Type"->"Moment","x"->xSupport,"Value"->M,"Kind"->"Reaction"|>}]


(* ::Input::Initialization:: *)
findAndInsertReactions[beam_?beamQ]:=Module[{reactions},reactions=convertReactionsForBeam[beam];
If[reactions===$Failed,Return[$Failed]];
ReplacePart[beam,Key["Loadings"]->Join[beam["Loadings"],reactions]]]


(* ::Input::Initialization:: *)
beamWithReactionsQ[beam_?beamQ]:=AnyTrue[beam["Loadings"],Lookup[#,"Kind",None]==="Reaction"&]

beamWithReactionsQ[___]:=False


beamReactions[beam_?beamWithReactionsQ]:=Select[beam["Loadings"],Lookup[#,"Kind",None]==="Reaction"&]


(* ::Input::Initialization:: *)
supportBCs[beam_?pinQ]:=y[#]==0&/@(#["x"]&/@beam["Supports"])
supportBCs[beam_?fixedEndQ]:={y[#]==0,y'[#]==0}&@(beam["Supports"][[1]]["x"])


(* ::Input::Initialization:: *)
sameBeamPositionQ[beam_?beamQ,x1_,x2_]:=Module[{rules},rules=Lookup[beam,"Numbers",{}];
TrueQ[PossibleZeroQ[(x1-x2)/. rules]]]


(* ::Input::Initialization:: *)
endMoment[beam_?beamWithReactionsQ,"Left"]:=Module[{selected},selected=Select[beam["Loadings"],momentQ[#]&&sameBeamPositionQ[beam,#["x"],0]&];
-Total[#["Value"]&/@selected]]

endMoment[beam_?beamWithReactionsQ,"Right"]:=Module[{selected},selected=Select[beam["Loadings"],momentQ[#]&&sameBeamPositionQ[beam,#["x"],beam["Length"]]&];
Total[#["Value"]&/@selected]]


(* ::Input::Initialization:: *)
endBCs[beamWithReactions_?beamWithReactionsQ]:={y''[0]==endMoment[beamWithReactions,"Left"],y''[beamWithReactions["Length"]]==endMoment[beamWithReactions,"Right"]}


(* ::Input::Initialization:: *)
fullBoundaryConditions[beamWithReactions_?beamWithReactionsQ]:=Join[endBCs[beamWithReactions],supportBCs[beamWithReactions]]


(* ::Input::Initialization:: *)
insertBeforeNumbers[target_?beamQ,key_String,obj_]:=If[KeyExistsQ[target,"Numbers"],Join[KeyDrop[target,{key,"Numbers"}],<|key->obj|>,<|"Numbers"->target["Numbers"]|>],Join[KeyDrop[target,key],<|key->obj|>]]


(* ::Input::Initialization:: *)
findAndInsertBoundaryConditions[beamWithReactions_?beamWithReactionsQ]:=insertBeforeNumbers[beamWithReactions,"Boundary conditions",fullBoundaryConditions@beamWithReactions]


(* ::Input::Initialization:: *)
beamWithBoundaryConditionsQ[beam_?beamQ]:=MemberQ[Keys@beam,"Boundary conditions"]
beamWithBoundaryConditionsQ[___]:=False


(* ::Input::Initialization:: *)
compensDistributed[arg_?distributedQ]:=-arg["Value"]HeavisideTheta[x-arg["x end"]]


(* ::Input::Initialization:: *)
equationTerm[beamWithReactions_?beamWithReactionsQ,arg_?forceQ]:=arg["Value"]DiracDelta[x-arg["x"]]
equationTerm[beam_?beamWithReactionsQ,arg_?momentQ]:=-arg["Value"] DiracDelta'[x-arg["x"]]*If[sameBeamPositionQ[beam,arg["x"],beam["Length"]],0,1]
equationTerm[beamWithReactions_?beamWithReactionsQ,arg_?distributedQ]:=arg["Value"]HeavisideTheta[x-arg["x begin"]]+compensDistributed[arg]


(* ::Input::Initialization:: *)
createEquation[beamWithReactions_?beamWithReactionsQ]:=y''''[x]==Total[equationTerm[beamWithReactions,#]&/@beamWithReactions["Loadings"]]


(* ::Input::Initialization:: *)
createAndInsertEquation[beamWithReactions_?beamWithReactionsQ]:=insertBeforeNumbers[beamWithReactions,"Equation",createEquation@beamWithReactions]


(* ::Input::Initialization:: *)
beamQuantities={"ShearForce","BendingMoment","RotationAngle","Deflection"};

beamQuantityLabels=<|"ShearForce"->"Shear force","BendingMoment"->"Bending moment","RotationAngle"->"Rotation angle","Deflection"->"Deflection"|>;

beamQuantityAxisLabels=<|"ShearForce"->"Q","BendingMoment"->"M","RotationAngle"->"\[Theta]","Deflection"->"y"|>;

beamQuantityQ[q_String]:=MemberQ[beamQuantities,q]
beamQuantityQ[___]:=False


(* ::Input::Initialization:: *)
endpointValueRules={HeavisideTheta[0]->1,HeavisideTheta[0.]->1,DiracDelta[0]->0,DiracDelta[0.]->0};


(* ::Input::Initialization:: *)
beamLoadPoint[arg_]:=Module[{argExpanded,slope},
argExpanded=Expand[arg];
slope=Coefficient[argExpanded,x];
If[TrueQ[slope==0],Return[$Failed]];
-(argExpanded/.x->0)/slope
]


(* ::Input::Initialization:: *)
beamLoadSlope[arg_]:=Module[{argExpanded,slope},argExpanded=Expand[arg];
slope=Coefficient[argExpanded,x];
If[TrueQ[slope==0],Return[$Failed]];
slope]


(* ::Input::Initialization:: *)
beamFallbackPrimitive[term_,n_Integer?Positive]:=Nest[
Integrate[#,x,GenerateConditions->False]&,
term,
n
]


(* ::Input::Initialization:: *)
beamNthPrimitiveTerm[term_,n_Integer?Positive]:=Module[{args,arg,a,slope,c,cNormalized},(* ============================================================*)(*Derivative of a concentrated moment term*)(* ============================================================*)args=Cases[term,HoldPattern[Derivative[1][DiracDelta][z_]]:>z,Infinity];
If[args=!={},arg=First@args;
c=term/.
HoldPattern[Derivative[1][DiracDelta][_]]->1;
If[!FreeQ[c,x],Return[beamFallbackPrimitive[term,n]]];
a=beamLoadPoint[arg];
slope=beamLoadSlope[arg];
If[a===$Failed||slope===$Failed,Return[beamFallbackPrimitive[term,n]]];
(*DiracDelta'[slope (x-a)]=DiracDelta'[x-a]/(slope Abs[slope])*)cNormalized=Simplify[c/(slope Abs[slope])];
Return[Switch[n,1,cNormalized DiracDelta[x-a],2,cNormalized HeavisideTheta[x-a],_,cNormalized (x-a)^(n-2)/(n-2)!*HeavisideTheta[x-a]]];];
(* ============================================================*)(*Concentrated-force term*)(* ============================================================*)args=Cases[term,HoldPattern[DiracDelta[z_]]:>z,Infinity];
If[args=!={},arg=First@args;
c=term/.
HoldPattern[DiracDelta[_]]->1;
If[!FreeQ[c,x],Return[beamFallbackPrimitive[term,n]]];
a=beamLoadPoint[arg];
slope=beamLoadSlope[arg];
If[a===$Failed||slope===$Failed,Return[beamFallbackPrimitive[term,n]]];
(*DiracDelta[slope (x-a)]=DiracDelta[x-a]/Abs[slope]*)cNormalized=Simplify[c/Abs[slope]];
Return[Switch[n,1,cNormalized HeavisideTheta[x-a],_,cNormalized (x-a)^(n-1)/(n-1)!*HeavisideTheta[x-a]]];];
(* ============================================================*)(*Beginning or end of a uniformly distributed load*)(* ============================================================*)args=Cases[term,HoldPattern[HeavisideTheta[z_]]:>z,Infinity];
If[args=!={},arg=First@args;
c=term/.
HoldPattern[HeavisideTheta[_]]->1;
If[!FreeQ[c,x],Return[beamFallbackPrimitive[term,n]]];
a=beamLoadPoint[arg];
slope=beamLoadSlope[arg];
If[a===$Failed||slope===$Failed,Return[beamFallbackPrimitive[term,n]]];
(*The BeamSolver-generated distributed-load terms have positive slope,normally exactly+1. If this is not the case,use Mathematica's general-purpose Integrate rather than making an unsafe assumption.*)If[!TrueQ[slope>0],Return[beamFallbackPrimitive[term,n]]];
Return[c (x-a)^n/n!*HeavisideTheta[x-a]];];
(* ============================================================*)(*Constant regular load*)(* ============================================================*)If[FreeQ[term,x],term x^n/n!,beamFallbackPrimitive[term,n]]]


(* ::Input::Initialization:: *)
beamNthPrimitive[expr_,n_Integer?Positive]:=Module[{expanded,terms},
expanded=Expand[expr];
terms=If[Head[expanded]===Plus,List@@expanded,{expanded}];
Total[beamNthPrimitiveTerm[#,n]&/@terms]
]


(* ::Input::Initialization:: *)
(*faster version*)
beamSolveDE[eq_,boundaryConditions_]:=Module[
{constants,rhs,particular,homogeneous,fields,boundaryRules,
algebraicBoundaryConditions,polynomials,coefficientData,constantValues},

constants=Table[Unique["beamC$"],{4}];
rhs=Last[eq];

(* Particular fields: shear, bending moment, slope numerator, deflection numerator *)
particular=Table[beamNthPrimitive[rhs,n],{n,4}];

(* Four integration constants, already propagated to every derivative *)
homogeneous={
constants[[1]],
constants[[1]]x+constants[[2]],
constants[[1]]x^2/2+constants[[2]]x+constants[[3]],
constants[[1]]x^3/6+constants[[2]]x^2/2+constants[[3]]x+constants[[4]]
};

fields=particular+homogeneous;

boundaryRules={
HoldPattern[Derivative[3][y][z_]]:>(fields[[1]]/.x->z),
HoldPattern[Derivative[2][y][z_]]:>(fields[[2]]/.x->z),
HoldPattern[Derivative[1][y][z_]]:>(fields[[3]]/.x->z),
HoldPattern[y[z_]]:>(fields[[4]]/.x->z)
};

algebraicBoundaryConditions=boundaryConditions/.boundaryRules/.endpointValueRules;
polynomials=algebraicBoundaryConditions/.Equal->Subtract;

coefficientData=Quiet@Check[Normal/@CoefficientArrays[polynomials,constants],$Failed];
If[coefficientData===$Failed||Length[coefficientData]=!=2,Return[$Failed]];

constantValues=Quiet@Check[
LinearSolve[coefficientData[[2]],-coefficientData[[1]]],
$Failed
];
If[constantValues===$Failed,Return[$Failed]];

(fields/.Thread[constants->constantValues])/.endpointValueRules
]


(* ::Input::Initialization:: *)
beamSolveDE[beamWithReactionsEquationsAndBCs_?(beamWithBoundaryConditionsQ[#]&&beamWithReactionsQ[#]&)]:=beamSolveDE[beamWithReactionsEquationsAndBCs["Equation"],beamWithReactionsEquationsAndBCs["Boundary conditions"]]


(* ::Input::Initialization:: *)
createBeamFunction[expression_]:=Function[{x1},Evaluate[(expression/.x->x1)]]


(* ::Input::Initialization:: *)
engineeringField[expr_]:=expr/. {HoldPattern[HeavisideTheta[z_]]:>UnitStep[z]}


engineeringShearField[expr_]:=engineeringField[expr/. {HoldPattern[DiracDelta[_]]->0}]


(* ::Input::Initialization:: *)
solveDEAndInsertSolution[beam_?(beamWithBoundaryConditionsQ[#]&&beamWithReactionsQ[#]&)]:=Module[{fields,scaledFields,solutions},fields=beamSolveDE[beam];
If[fields===$Failed,Return[$Failed]];
scaledFields={engineeringShearField[fields[[1]]],engineeringField[fields[[2]]],engineeringField[fields[[3]]/(beam["E"] beam["J"])],engineeringField[fields[[4]]/(beam["E"] beam["J"])]};
solutions=AssociationThread[beamQuantities,createBeamFunction/@scaledFields];
insertBeforeNumbers[beam,"Solutions",solutions]]


(* ::Input::Initialization:: *)
symbolsInExpr[arg_]:=Cases[Variables@Level[arg,{-1}],_Symbol]


(* ::Input::Initialization:: *)
valuesQ[arg_List]:=AllTrue[arg,MatchQ[#,Rule[_Symbol,_?NumberQ]]&]&&noNullInsideQ[arg]

valuesQ[___]:=False


(* ::Input::Initialization:: *)
beamParameterRules[beam_?beamQ]:=Lookup[beam,"Numbers",{}]


(* ::Input::Initialization:: *)
realNumericQ[z_]:=Quiet@Check[NumberQ[N[z]]&&TrueQ[Chop[Im[N[z]]]==0],False]


positiveRealQ[z_]:=realNumericQ[z]&&TrueQ[N[z]>0]


(* ::Input::Initialization:: *)
loadInsideBeamQ[load_?forceQ,L_]:=realNumericQ[load["x"]]&&realNumericQ[load["Value"]]&&TrueQ[0<=N[load["x"]]<=N[L]]


loadInsideBeamQ[load_?momentQ,L_]:=realNumericQ[load["x"]]&&realNumericQ[load["Value"]]&&TrueQ[0<=N[load["x"]]<=N[L]]


loadInsideBeamQ[load_?distributedQ,L_]:=realNumericQ[load["x begin"]]&&realNumericQ[load["x end"]]&&realNumericQ[load["Value"]]&&TrueQ[0<=N[load["x begin"]]<=N[load["x end"]]<=N[L]]


loadInsideBeamQ[___]:=False


(* ::Input::Initialization:: *)
beamPhysicalQ[beam_?beamQ]:=Module[{L,supportPositions},L=beam["Length"];
If[!positiveRealQ[L]||!positiveRealQ[beam["E"]]||!positiveRealQ[beam["J"]],Return[False]];
supportPositions=#["x"]&/@beam["Supports"];
If[!AllTrue[supportPositions,realNumericQ],Return[False]];
If[!AllTrue[supportPositions,TrueQ[0<=N[#]<=N[L]]&],Return[False]];
(*Two simple supports must not coincide*)If[pinQ[beam]&&TrueQ[Chop[N[supportPositions[[1]]-supportPositions[[2]]]]==0],Return[False]];
AllTrue[beam["Loadings"],loadInsideBeamQ[#,L]&]]

beamPhysicalQ[___]:=False


(* ::Input::Initialization:: *)
beamReadyQ[beam_?beamQ]:=Module[{rules,requiredSymbols,resolvedBeam},rules=beamParameterRules[beam];
If[!valuesQ[rules],Return[False]];
If[!(pinQ[beam]||fixedEndQ[beam]),Return[False]];
requiredSymbols=DeleteDuplicates@symbolsInExpr[KeyDrop[beam,"Numbers"]];
If[!ContainsAll[First/@rules,requiredSymbols],Return[False]];
resolvedBeam=KeyDrop[beam,"Numbers"]/. rules;
beamPhysicalQ[resolvedBeam]]

beamReadyQ[___]:=False


(* ::Input::Initialization:: *)
beamSolve::invalid="The beam definition is invalid, contains unsupported supports, or has unresolved parameters.";

beamSolve::reactions="The support reactions could not be determined.";

beamSolve::solution="The beam differential equation could not be solved.";
beamSolve[beam_?beamReadyQ]:=Module[{beamWithReactions,beamWithBCs,beamWithEquation,result},beamWithReactions=findAndInsertReactions[beam];
If[beamWithReactions===$Failed,Message[beamSolve::reactions];
Return[$Failed]];
beamWithBCs=findAndInsertBoundaryConditions[beamWithReactions];
beamWithEquation=createAndInsertEquation[beamWithBCs];
result=solveDEAndInsertSolution[beamWithEquation];
If[result===$Failed,Message[beamSolve::solution];
Return[$Failed]];
result/. DiracDelta[0]->0]

beamSolve[___]:=(Message[beamSolve::invalid];
$Failed)


(* ::Input::Initialization:: *)
solvedBeamQ[arg_?beamQ]:=MemberQ[Keys@arg,"Solutions"]
solvedBeamQ[___]:=False


(* ::Input::Initialization:: *)
solvedBeamWithValuesQ[arg_?solvedBeamQ]:=Not@MemberQ[Keys@arg,"Numbers"]
solvedBeamWithValuesQ[___]:=False


(* ::Input::Initialization:: *)
myPlot[fun_,limits_,opts:OptionsPattern[]]:=Plot[fun,limits,opts,GridLines->Automatic,
Frame->True,PlotStyle->Thick,PlotRange->Full,RotateLabel->False,
LabelStyle->{Directive[Black,Bold],10}, ImageSize->400,ImagePadding->{{100,30},{30,1}}]


(* ::Input::Initialization:: *)
(*beamPlots[solvedBeam_?solvedBeamWithValuesQ,opts:OptionsPattern[]]:=myPlot[solvedBeam["Solutions"][#][x],{x,-0.001 solvedBeam["Length"],1.001 solvedBeam["Length"]},Exclusions->None,FrameLabel->{"x",beamQuantityAxisLabels[#]},PlotLabel->beamQuantityLabels[#],AxesOrigin->{0,0},Filling->Axis,opts]&/@beamQuantities*)


(* ::Input::Initialization:: *)
beamPlots[solvedBeam_?solvedBeamWithValuesQ,opts:OptionsPattern[]]:=Column[myPlot[solvedBeam["Solutions"][#][x],{x,-0.001 solvedBeam["Length"],1.001 solvedBeam["Length"]},Exclusions->None,FrameLabel->{"x",beamQuantityAxisLabels[#]},PlotLabel->beamQuantityLabels[#],AxesOrigin->{0,0},AspectRatio->1/3,Filling->Axis,opts]&/@beamQuantities]


(* ::Input::Initialization:: *)
beamBreakPoints[beam_?solvedBeamWithValuesQ]:=Module[{points},points=Flatten[Map[Which[forceQ[#],{#["x"]},momentQ[#],{#["x"]},distributedQ[#],{#["x begin"],#["x end"]},True,{}]&,beam["Loadings"]]];
Sort@DeleteDuplicates[points]]


(* ::Input::Initialization:: *)
beamSnapPosition[p_,{a_,b_}]:=Module[{tol},tol=10^-7 Max[1,Abs[N[a]],Abs[N[b]]];
Which[Abs[N[p-a]]<=tol,a,Abs[N[p-b]]<=tol,b,True,Clip[p,{a,b}]]]


(* ::Input::Initialization:: *)
beamIntervalExtrema[fun_,{a_,b_}]:=Module[{expr,extrema},If[TrueQ[a==b],Return[{}]];
expr=Quiet@FullSimplify[fun[x],Assumptions->a<x<b];
extrema=Quiet@Check[Through[{NMinimize,NMaximize}[{expr,a<=x<=b},x]],$Failed];
If[extrema===$Failed,{},Function[result,Module[{position},position=beamSnapPosition[x/. Last[result],{a,b}];
{N[expr/. x->position],position}]]/@extrema]]


(* ::Input::Initialization:: *)
beamOneSidedCandidates[fun_,point_]:={{Quiet@Limit[fun[x],x->point,Direction->"FromBelow"],point},{Quiet@Limit[fun[x],x->point,Direction->"FromAbove"],point}}


(* ::Input::Initialization:: *)
beamMaxValue::quantity="Unknown quantity `1`. Valid quantities are: `2`.";

beamMaxValue::interval="Invalid interval `1`. It must satisfy 0 <= xmin <= xmax <= `2`.";

beamMaxValue::optimization="The maximum absolute value of `1` could not be determined.";

beamMaxValue[solvedBeam_?solvedBeamWithValuesQ,quantity_String?beamQuantityQ,interval:{xmin_,xmax_}]/;0<=xmin<=xmax<=solvedBeam["Length"]:=Module[{fun,internalPoints,boundaries,intervals,candidates,best},fun=solvedBeam["Solutions"][quantity];
internalPoints=Select[beamBreakPoints[solvedBeam],xmin<#<xmax&];
boundaries=Join[{xmin},internalPoints,{xmax}];
intervals=Partition[boundaries,2,1];
candidates=Flatten[beamIntervalExtrema[fun,#]&/@intervals,1];
(*Interior values at the two beam/interval endpoints*)candidates=Join[candidates,{{Quiet@Limit[fun[x],x->xmin,Direction->"FromAbove"],xmin},{Quiet@Limit[fun[x],x->xmax,Direction->"FromBelow"],xmax}}];
(*Both sides of every internal discontinuity*)candidates=Join[candidates,Flatten[beamOneSidedCandidates[fun,#]&/@internalPoints,1]];
candidates=Select[candidates,Quiet@Check[NumericQ[N[First[#]]],False]&];
If[candidates==={},Message[beamMaxValue::optimization,quantity];
Return[$Failed]];
best=First@MaximalBy[candidates,Abs[N[First[#]]]&];
<|"Quantity"->quantity,"Value"->First[best],"Position"->Last[best]|>]

beamMaxValue[solvedBeam_?solvedBeamWithValuesQ,quantity_String?beamQuantityQ]:=beamMaxValue[solvedBeam,quantity,{0,solvedBeam["Length"]}]

beamMaxValue[solvedBeam_?solvedBeamWithValuesQ,quantity_String,___]/;!beamQuantityQ[quantity]:=(Message[beamMaxValue::quantity,quantity,StringRiffle[beamQuantities,", "]];
$Failed)

beamMaxValue[solvedBeam_?solvedBeamWithValuesQ,quantity_String?beamQuantityQ,interval:{_,_}]:=(Message[beamMaxValue::interval,interval,solvedBeam["Length"]];
$Failed)


(* ::Input::Initialization:: *)
beamInitialParameters[solvedBeamWithValues_?solvedBeamWithValuesQ]:=<|"RotationAngle"->solvedBeamWithValues["Solutions"]["RotationAngle"][0.],"Deflection"->solvedBeamWithValues["Solutions"]["Deflection"][0.]|>


(* ::Input::Initialization:: *)
End[];
EndPackage[]
