function[out_fl]=mortality_flowMB(fl, th, sl, Ndim, Mdim)
% function to calculate mortality percentage due to flow velocity
% Input:
%       - fl = matrix with maximum flow velocities
%       - th = threshold 
%       - sl = slope of fct
% Be careful: output already in fractions 0-1 and not in percentages! Also,
% the y-axis is reduced to 0-1 which leads to very small dmax-velocities 

% MB: Function f(x)= sl*x+b; for y=0: b=-sl*th
b= -th*sl; % calculate variable b (cross with y-axis)
dmax=(1-b)/sl; % no. of days when 100% is died off
fct= (sl.*(fl)+b); % determines all mortality values over the grid 
%% import flooding days data from mort_code fl
out_fl=zeros(Ndim,Mdim); % creates matrix
B=find(fl>dmax); % determines cells with 100% mortality
out_fl(B)=1; % write to output matrix 100% mortality
C=find(dmax>fl & fl>th); % determines cells where fct applies to determine mortality
out_fl(C)=fct(C); % write correlated values to output matrix


end % end of function