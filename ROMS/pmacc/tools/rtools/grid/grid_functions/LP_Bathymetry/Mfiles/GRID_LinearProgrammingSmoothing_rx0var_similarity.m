function NewBathy=GRID_LinearProgrammingSmoothing_rx0var_similarity(...
    MSK, Hobs, rx0matrix, SignConst, AmpConst, MaxSimilarity)
% GRID_LinearProgrammingSmoothing_rx0_similarity(...
%    MSK, Hobs, rx0matrix, SignConst, AmpConst, MaxSimilarity)
%
% ---MSK(eta_rho,xi_rho) is the mask of the grd
%      1 for sea
%      0 for land
% ---Hobs(eta_rho,xi_rho) is the raw depth of the grid
% ---rx0matrix is the target rx0 roughness factor matrix
% ---SignConst(eta_rho,xi_rho) matrix of 0, +1, -1
%      +1  only bathymetry increase are allowed.
%      -1  only bathymetry decrease are allowed.
%      0   increase and decrease are allowed.
%      (put 0 if you are indifferent)
% ---AmpConst(eta_rho,xi_rho) matrix of reals.
%      coefficient alpha such that the new bathymetry should
%      satisfy to  |h^{new} - h^{raw}| <= alpha h^{old}
%      (put 10000 if you are indifferent)
% ---MaxSimilarity is the maximal expansion factor on every
%    cell
[eta_rho, xi_rho]=size(MSK);
tol=0.0001;
K=find(MSK == 1);
if (min(Hobs(K)) < tol)
  disp('The bathymetry should always be positive');
  error('Please correct');
end;
%
[iList, jList, sList, Constant]=...
    GRID_LinProgGetIJS_rx0(MSK, Hobs, rx0matrix);
%
[iListApp, jListApp, sListApp, ConstantApp]=...
    GRID_LinProgGetIJS_maxamp(MSK, Hobs, AmpConst);
[iList, jList, sList, Constant]=...
    LP_MergeIJS_listings(...
	iList, jList, sList, Constant, ...
	iListApp, jListApp, sListApp, ConstantApp);
%
[iListApp, jListApp, sListApp, ConstantApp]=...
    GRID_LinProgGetIJS_signs(MSK, SignConst);
[iList, jList, sList, Constant]=...
    LP_MergeIJS_listings(...
	iList, jList, sList, Constant, ...
	iListApp, jListApp, sListApp, ConstantApp);
%
[iListApp, jListApp, sListApp, ConstantApp]=...
    GRID_LinProgGetIJS_similarity(MSK, Hobs, MaxSimilarity);
[iList, jList, sList, Constant]=...
    LP_MergeIJS_listings(...
	iList, jList, sList, Constant, ...
	iListApp, jListApp, sListApp, ConstantApp);
%
TotalNbVert=sum(MSK(:));
ObjectiveFct=zeros(2*TotalNbVert, 1);
for iVert=1:TotalNbVert
  ObjectiveFct(TotalNbVert+iVert,1)=1;
end;
[ValueFct, ValueVar, testfeasibility]=...
    LP_SolveLinearProgram(...
	iList, jList, sList, Constant, ObjectiveFct);
if (testfeasibility == 0)
  NewBathy=NaN*ones(eta_rho, xi_rho);
  return;
end;
%
correctionBathy=zeros(eta_rho, xi_rho);
nbVert=0;
for iEta=1:eta_rho
  for iXi=1:xi_rho
    if (MSK(iEta, iXi) == 1)
      nbVert=nbVert+1;
      correctionBathy(iEta, iXi)=ValueVar(nbVert);
    end;
  end;
end;
NewBathy=Hobs+correctionBathy;
