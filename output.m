(*importing output data*)
pts = Import["...\\output.csv"];

(*space rescaling parameters*)
nrand = 10000;
vf = 0.05;





Off[LinearSolve::luc];

RBF[pts_, T_] := Module[{n, d, phi, Phi, P, F, M, v, sol, lam, b, a},
  
  n = Length[pts];
  d = Length[pts[[1]]] - 1;
  
  phi[r_] := r^3;
  
  Phi = Table[
    phi[Norm[T.(Most[pts[[i]]] - Most[pts[[j]]])]], {i, n}, {j, n}];
  P = Table[Append[Most[pts[[i]]], 1.], {i, n}];
  F = Table[Last[pts[[i]]], {i, n}];
  
  M = Table[0., {n + d + 1}, {n + d + 1}];
  M[[1 ;; n, 1 ;; n]] = Phi;
  M[[1 ;; n, n + 1 ;; n + d + 1]] = P;
  M[[n + 1 ;; n + d + 1, 1 ;; n]] = Transpose[P];
  
  v = Table[0., {n + d + 1}];
  v[[1 ;; n]] = F;
  
  sol = LinearSolve[M, v];
  lam = sol[[1 ;; n]];
  b = sol[[n + 1 ;; n + d]];
  a = sol[[n + d + 1]];
  
  Sum[lam[[i]] phi[Norm[T.(# - Most[pts[[i]]])]], {i, n}] + b.# + a &
  
  ]

d = Length[pts[[1]]] - 1;

(*space rescaling*)
If[d == 1,
 
 fit = RBF[pts, IdentityMatrix[1]];,
 
 pcafit = RBF[pts, IdentityMatrix[d]];
 
 cover = Table[RandomReal[], {nrand}, {d}];
 cover = Table[Append[cover[[i]], pcafit[cover[[i]]]], {i, nrand}];
 cloud = SortBy[cover, Last][[1 ;; Ceiling[vf*nrand]]];
 cloud = Table[Most[cloud[[i]]], {i, Length[cloud]}];
 
 es = Eigensystem[Covariance[cloud]];
 T = Table[es[[2, i]]/Sqrt[es[[1, i]]], {i, d}];
 T = T/Norm[T, "Frobenius"];
 
 fit = RBF[pts, T];
 ]


(*plotter*)
If[d == 1,
 Show[
  ListPlot[pts, PlotStyle -> {Black, PointSize[Medium]}],
  Plot[fit[{x}], {x, 0, 1}],
  ImageSize -> 500,
  BaseStyle -> 14
  ]
 ]

If[d == 2,
 Show[
  ContourPlot[fit[{x, y}], {x, 0, 1}, {y, 0, 1}, Contours -> 50, 
   ColorFunction -> "DarkRainbow"],
  ListPlot[Table[{pts[[i, 1]], pts[[i, 2]]}, {i, Length[pts]}], 
   PlotStyle -> {Black, PointSize[Medium]}],
  ImageSize -> 500,
  BaseStyle -> 14
  ]
 ]

If[d > 2,
 
 min = SortBy[pts, Last][[1]];
 
 Show[
  
  Append[Table[
    ListPlot[Most[pts[[i]]], Joined -> True, 
     PlotStyle -> Lighter[Pink, Last[pts[[i]]]]], {i, Length[pts]}], 
   ListPlot[Most[min], Joined -> True, PlotStyle -> Black]],
  
  ListPlot[Table[{{i, 0}, {i, 1}}, {i, d}], Joined -> True, 
   PlotStyle -> Table[{Gray, Dashed}, d]],
  
  PlotRange -> {{1, d}, {0, 1}},
  Axes -> False,
  ImageSize -> 500
  ]
 ]

(*fit minimizing*)
Minimize[fit[Table[x[i], {i, d}]], Table[x[i], {i, d}]]

(*sorted samples*)
SortBy[pts, Last] // TableForm
