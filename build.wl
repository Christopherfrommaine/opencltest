(* ::Package:: *)

StripZeros=CompiledCodeFunction[<|"Signature" -> TypeSpecifier[{"PackedArray"["Integer64", LiteralType[1, "Integer64"]]} -> "PackedArray"["Integer64", LiteralType[1, "Integer64"]]], "Input" -> Compile`Program[{}, Function[Typed[list, TypeSpecifier["PackedArray"]["MachineInteger", 1]], Module[{i = 1, j = Length[list]}, If[Module[{i0 = Length[list]}, While[And[i0 > 0, Part[list, i0] == 0], Decrement[i0]; Null]; i0 == 0], Return[Table[0, {iter, 0}]]]; While[Part[list, i] == 0, Increment[i]]; While[Part[list, j] == 0, Decrement[j]]; Part[list, Span[i, j]]]]], "ErrorFunction" -> Automatic, "InitializationName" -> "Initialization_02f43433_0703_4172_ba59_df259ca94f52", "ExpressionName" -> "Main_ExprInvocation", "CName" -> "Main_CInvocation", "FunctionName" -> "Main", "SystemID" -> "Linux-x86-64", "VersionData" -> {14.3, 0, 0}, "CompiledIR" -> <|"Linux-x86-64" -> ByteArray[CompressedData["
1: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

"]]|>, "ExternalLibraryPaths" -> {"CompilerCoreRuntime.so"}, "orcInstance" -> 635198080, "orcModuleId" -> 646412208|>, 139476073404432, 139476073403616, 139476073404368, 139476073402368, "{\"PackedArray\"[\"Integer64\", LiteralType[1, \"Integer64\"]]} -> \"PackedArray\"[\"Integer64\", LiteralType[1, \"Integer64\"]]"];


rca=ResourceFunction["RandomCellularAutomatonRule"];

RandomGoodRule[K_:2, R_:1]:=(

GoodRuleCondition[rule_]:=If[Length[Last[CellularAutomaton[rule, {RandomInteger[K-1, 100], 0}, 100]]]>150, False, With[{l=Table[Length[StripZeros[CellularAutomaton[rule, {RandomInteger[K-1, 100], 0}, {{{100}}}]]], 10]}, Mean[l]<100&&Min[l]==0&&Max[l]<150&&Max[l]>0]];

ParallelTry[If[GoodRuleCondition[#], #, $Failed]&,ParallelTable[{rca[{K, R}, "Quiescent"->True, "Type"->"Symmetric"]["RuleNumber"], K, R}, 10000]]
);

RandomGoodTotalisticRule[K_:2, R_:1]:=(

GoodRuleCondition[rule_]:=If[Length[Last[CellularAutomaton[rule, {RandomInteger[K-1, 100], 0}, 100]]]>150, False, With[{l=Table[Length[StripZeros[CellularAutomaton[rule, {RandomInteger[K-1, 100], 0}, {{{100}}}]]], 10]}, Mean[l]<100&&Min[l]==0&&Max[l]<150&&Max[l]>0]];

ParallelTry[If[GoodRuleCondition[#], #, $Failed]&,ParallelTable[{rca[{K, R}, "Quiescent"->True, "Type"->"Totalistic"]["TotalisticCode"], {K, 1}, R}, 10000]]
);


Clear[StrongAssert]
StrongAssert[test_, messages__]:=If[!test, Print[messages]; Quit[4]]
SetAttributes[StrongAssert, HoldRest]

Clear[f]
f[formatString_String, args___]:=Module[{str=formatString, arglist={args}},
Do[str=StringReplace[str, "``"->ToString[arglist[[i]]],1], {i, Length[arglist]}]; str]

Clear[StringJoinTable]
StringJoinTable[args___]:=StringJoin[Table[args]]
SetAttributes[StringJoinTable, HoldAll]

PointApplyRule[rule_,init_]:=CellularAutomaton[rule, init, 1][[2,(Length[init]+1)/2]]

Clear[AnalyzeRule];
AnalyzeRule[{n_, k_, r_}]:=AnalyzeRule[{n, k, r}]=Module[{rule={n,k, r}},<|
"Rule"->rule, (* may be overrided by a totalistic rule *)
"NormalRule"->rule,  (* always {booleanfunctionnumber, colors, radius} *)
"Colors"->k,
"Radius"->r,
"Totalistic"->False,
"Number"->n,
"Quiescent"->Not[Positive[PointApplyRule[rule, ConstantArray[0, 2r+1]]]],
"Symmetric"->AllTrue[Tuples[Range[0, k-1], 2r+1], PointApplyRule[rule, #]==PointApplyRule[rule, Reverse[#]]&]
|>]

AnalyzeRule[{n_, {k_, 1}, r_}]:=AnalyzeRule[{n, {k, 1}, r}]=With[
{rule={n, {k, 1}, r}},{num=FromDigits[Reverse[PointApplyRule[rule, #]&/@Tuples[Range[0, k-1], 2r+1]], k]},
Join[AnalyzeRule[{num, k, r}],<|"Rule"->rule, "Totalistic"->True|>]
]
AnalyzeRule[{n_, k_}]:=AnalyzeRule[{n, k, 1}]
AnalyzeRule[{n_}]:=AnalyzeRule[{n, 2}]
AnalyzeRule[n_]:=AnalyzeRule[{n}]

Clear[Bits]
Bits[n_Integer, len_Integer:64]:=IntegerDigits[n, 2, len]
Bits[n_List, len_Integer:64]:=IntegerDigits[#, 2, len]&/@n


Clear[XorList]
XorList[inp__]:=Xor@@@Transpose[{inp}]

UpperHalf[list_List]:=list[[;;(Length[list]/2)]]
LowerHalf[list_List]:=list[[(Length[list]/2+1);;]]

Clear[ShannonForm]
ShannonForm[fmap_List]:=Module[{index, upper, lower, upperExpr, lowerExpr, outputExpr},
index=Log2[Length[fmap]];

If[index<=0, Return[First[fmap]]];

upper=fmap[[1;;;;2]];
lower=fmap[[2;;;;2]];

lowerExpr=ShannonForm[lower];
upperExpr=ShannonForm[upper];

outputExpr=Or[And[upperExpr,  Not@Slot[index]], And[lowerExpr,Slot[index]]];

FullSimplify[outputExpr]
]

ShannonXorForm[fmap_List]:=Module[{index, upper, lower, xorVector, upperExpr, xorExpr, outputExpr},
index=Log2[Length[fmap]];

If[index<=0, Return[First[fmap]]];

upper=fmap[[1;;;;2]];
lower=fmap[[2;;;;2]];

xorVector=XorList[upper, lower];

xorExpr=ShannonXorForm[xorVector];
upperExpr=ShannonXorForm[upper];

outputExpr=Xor[upperExpr, And[Slot[index], xorExpr]];

FullSimplify[outputExpr]
]

SplitOnVariable[fmap_List,k_Integer]:=Module[
{n=Log2[Length[fmap]],upper={},lower={},bits},
Do[
bits=IntegerDigits[i,2,n];
If[bits[[k]]==0,
AppendTo[upper,fmap[[i+1]]],
AppendTo[lower,fmap[[i+1]]]
],{i,0,Length[fmap]-1}];
{upper,lower}]

ShannonArbitraryOrdered[fmap_List,vars_List]:=ShannonArbitraryOrdered[fmap,vars]=Module[{n,candidates,upper,lower,xorVector,upperExpr,xorExpr,remainingVars},
n=Length[vars];
If[n==0,Return[First[fmap]]];
candidates=Table[
{upper,lower}=SplitOnVariable[fmap,k];
xorVector=XorList[upper,lower];
remainingVars=Delete[vars,k];
upperExpr=ShannonArbitraryOrdered[upper,remainingVars];
xorExpr=ShannonArbitraryOrdered[xorVector,remainingVars];
Xor[upperExpr,And[Slot[vars[[k]]],xorExpr]],{k,n}];
FullSimplify[First@MinimalBy[candidates,VertexCount@*ExpressionTree, 1]]];

ShannonArbitraryOrdered[fmap_List]:=EchoTiming[ShannonArbitraryOrdered[fmap,Range[Log2[Length[fmap]]]]]

ComputeXorDC[upper_List,lower_List]:=Transpose@MapThread[Function[{a,b},Which[a==="X"&&b==="X",{"X","X"},(*both free:keep as-is*)a==="X",{b,0},(*fix upper:=lower*)b==="X",{a,0},(*fix lower:=upper*)True,{a,Xor[a,b]}]],{upper,lower}]

ShannonXorFormDC[fmap_List]:=Module[{index,upper,lower,resolvedUpper,xorVector,upperExpr,xorExpr},index=Log2[Length[fmap]];
(*Base case:leaf value.Assign "X"\[RightArrow]0 (arbitrary but benign choice)*)If[index<=0,Return[If[First[fmap]==="X",0,First[fmap]]]];
upper=UpperHalf[fmap];
lower=LowerHalf[fmap];
{resolvedUpper,xorVector}=ComputeXorDC[upper,lower];
xorExpr=ShannonXorFormDC[xorVector];
upperExpr=ShannonXorFormDC[resolvedUpper];(*note:resolved,not raw upper*)
FullSimplify[Xor[upperExpr,And[Slot[index],xorExpr]]]]

ShannonArbitraryOrderedDefer[fmap_List,vars_List]:=ShannonArbitraryOrderedDefer[fmap,vars]=Module[{n,candidates,upper,lower,xorVector,upperExpr,xorExpr,remainingVars},n=Length[vars];
If[n==0,Return[First[fmap]]];
candidates=Table[
{upper,lower}=SplitOnVariable[fmap,k];
xorVector=XorList[upper,lower];
remainingVars=Delete[vars,k];
upperExpr=ShannonArbitraryOrderedDefer[upper,remainingVars];
xorExpr=ShannonArbitraryOrderedDefer[xorVector,remainingVars];
Xor[upperExpr,And[Slot[vars[[k]]],xorExpr]],{k,n}];
First@MinimalBy[candidates,VertexCount@*ExpressionTree]
];

ShannonArbitraryOrderedDefer[fmap_List]:=FullSimplify[ShannonArbitraryOrderedDefer[fmap,Range[Log2[Length[fmap]]]]]

ConvertExprToString[expr_]:=StringReplace[f["``",StringReplace[ToString[expr, TraditionalForm],{"\[And]"->"&", "\[Or]"->"|", "\[Not]"->"~", "\[Xor]"->" ^ ", " "->"", "False"->"0"}]], {"~ "->"~"}]


SearchingFunctionOriginal = With[{
nbd=NotebookDirectory[]},

Function[{rule, min, max, timeout}, Module[{ar, n, k, r, bits, MinimalBooleanForm, filledTemplateFile},

helperFile=Import[nbd<>"kernels/helper.cl"];
templateFile=Import[nbd<>"kernels/template.cl", "Text"];
filledTemplateFile=templateFile;
TemplateReplace[srule_]:=(filledTemplateFile=StringReplace[filledTemplateFile,srule];);

ar=AnalyzeRule[rule];
n=ar["Number"];
k=ar["Colors"];
r=ar["Radius"];

bits=BitLength[k-1];

StrongAssert[ar["Quiescent"], "Rule Not Quiescent"];

MinimalBooleanForm[bf_]:=First[MinimalBy[
ParallelMap[
TimeConstrained[Replace[#[],Implies[a_,b_]->Or[Not[a],b], All],5,BooleanConvert[bf,"CNF"][[1]]]&,
{
BooleanMinimize[bf,"CNF"][[1]]&,
BooleanMinimize[bf,"DNF"][[1]]&,
BooleanMinimize[bf,"ANF"][[1]]&,
BooleanMinimize[bf,"OR"][[1]]&,
ShannonForm[Reverse@BooleanTable[bf]]&,
ShannonXorForm[Reverse@BooleanTable[bf]]& ,
ShannonArbitraryOrderedDefer[Reverse@BooleanTable[bf]]&,ShannonXorFormDC[If[Max[FromDigits[#,2]&/@Partition[Boole[#],bits]]<k,bf@@#,"X"]&/@Tuples[{False,True},BooleanVariables[bf]]]& 
}],VertexCount@*ExpressionTree,1]];

fullUpdateRule=Catenate[Bits[#, bits]]->Bits[PointApplyRule[rule, #], bits]&/@Tuples[Range[0, k-1], 2r+1];
o1=MinimalBooleanForm/@BooleanFunction[fullUpdateRule][[1, All, 0]];
o2=Table[ConvertExprToString[expr/.Table[Slot[i]->"a"<>ToString[i], {i,bits*(2r+1)}]], {expr, o1}];
o3=StringRiffle[Table[f["u256_shl((``) & NTHBITSMASK, ``)", o2[[i]], bits-i], {i, bits}], " | "];
If[bits==1, o3=First[o2]];

preprereqs=f["    u256 o = *oPoint;\n"];

prereqs=StringJoinTable[f[Which[Positive[i-bits],"    u256 a`` = u256_shl(o, ``);\n", Negative[i-bits], "    u256 a`` = u256_shr(o, ``);\n", True,"    u256 a`` = o;\n"], i, Abs[i-bits]], {i, (2r+1)*bits}];

updateFunction=f["static inline void update256(u256 *restrict oPoint) {
    u256 o = *oPoint;

``
    *oPoint = ``;
}\n",prereqs, o3 ];

TemplateReplace["TEMPLATE_update256"->updateFunction];


tohex=Dispatch[{"10"->"A", "11"->"B", "12"->"C", "13"->"D", "14"->"E", "15"->"F"}];
NumberAsHexString[i_Integer]:=StringJoin["0x",(ToString/@IntegerDigits[i, 16, 16])/.tohex,"ULL"];
bitstemplate=f["#define BITS ``\n", bits];
TemplateReplace["TEMPLATE_BITS"->bitstemplate];
ktemplate=f["#define K ``\n", k];
TemplateReplace["TEMPLATE_K"->ktemplate];
rtemplate=f["#define R ``\n", r];
TemplateReplace["TEMPLATE_R"->rtemplate];
symmetrictemplate=f["#define SYMMETRIC ``\n", Boole[ar["Symmetric"]]];
TemplateReplace["TEMPLATE_SYMMETRIC"->symmetrictemplate];
topmostbitmask=f["#define TOPMOSTBITSMASK ``\n", NumberAsHexString[FromDigits[Table[Boole[i<=bits*(2r+1)], {i, 64}], 2]]];
TemplateReplace["TEMPLATE_TOPMOSTBITSMASK"->topmostbitmask];
bottommostbitsmask=f["#define BOTTOMMOSTBITSMASK ``\n", NumberAsHexString[FromDigits[Reverse@Table[Boole[i<=r+1], {i, 64}], 2]]];
TemplateReplace["TEMPLATE_BOTTOMMOSTBITSMASK"->bottommostbitsmask];
bottombitsmask=f["#define BOTTOMBITSMASK ``\n", NumberAsHexString[BitShiftLeft[1, bits]-1]];
TemplateReplace["TEMPLATE_BOTTOMBITSMASK"->bottombitsmask];
nthbitmask=f["#define NTHBITSMASK (u256)(``)",StringRiffle[StringJoin["0x",#, "ULL"]&/@Partition[ToString/@IntegerDigits[FromDigits[Flatten[ConstantArray[Reverse@UnitVector[bits, 1], Ceiling[256/bits]]][[;;256]], 2], 16]/.tohex, 16], ", "]];
TemplateReplace["TEMPLATE_NTHBITSMASK"->nthbitmask];
allowedIntegers=Bits[Range[0, k-1]];
validpackedintegertemplate=f["``", ConvertExprToString[MinimalBooleanForm[BooleanFunction[#->Boole[!MemberQ[allowedIntegers, #]]&/@Tuples[{0, 1}, bits]]]/.Slot[x_]:>f["(x >> ``)", bits-x]]];
TemplateReplace["TEMPLATE_VALID_PACKED_INTEGER"->validpackedintegertemplate];

outputFile=helperFile<>filledTemplateFile;
file=OpenWrite[nbd<>"kernels/kernel.cl", PageWidth->Infinity];
WriteString[file, outputFile];
Close[file];

shellscript=f["#!/bin/bash\ncd ``\ntimeout `` ./run.sh `` ``\n", nbd, 1+timeout, min, max];
shellfile=OpenWrite[nbd<>"run_in_env.sh", PageWidth->Infinity];
WriteString[shellfile, shellscript];
Close[shellfile];

res=TimeConstrained[stdout=RunProcess[{"bash", "-l", nbd<>"run_in_env.sh"}], timeout, $TimedOut];
If[res===$TimedOut, Return[$TimedOut]];

ConvertFromPackedInt[n_Integer]:=FromDigits[FromDigits[#, 2]&/@Partition[IntegerDigits[n, 2, 256], bits], k];
ConvertFromPackedIntList[n_Integer]:=FromDigits[#, 2]&/@Partition[IntegerDigits[n, 2, 256], bits];

ReadOutputFile[]:=Rest[Sort[Developer`ToPackedArray[ReadList[StringToStream[First[StringCases[StringReplace[Import[nbd<>"out.txt"], "\n"->""], "{"~~x__~~"}":>ToString[{x}]], "{}"]]][[1]]]]];

ReadOutputFile[]
]]];


GPUStructureSearch[rule_, min_Integer:0, max_Integer:10000, timeout_Integer:60]:=SearchingFunctionOriginal[rule, min, max, timeout]
