function[out_fl]=mortality_flood_frequencyMB(fl, th, sl, Ndim, Mdim)
% function to calculate mortality percentage due to flow velocity
% Input:
%       - fl = matrix with flooded days
%       - th = threshold
%       - sl = slope of the function
% out_fl: matrix with mortality values [% of fraction removed]
% N,M: grid size

% MB: Function f(x)= sl*x+b; for y=0: b=-sl*th
b= -th*sl; % calculate variable b (cross with y-axis)
dmax=round((1-b)/sl,2); % no. of days when 100% is died off
fct= (sl.*(fl)+b); % determines all mortality values over the grid
%% import flooding days data from mort_code fl
out_fl=zeros(Ndim,Mdim); % creates matrix

B=find(fl>dmax); % determines cells with 100% mortality
out_fl(B)=1; % write to output matrix
C=find(dmax>fl & fl>th); % determines cells where fct applies to determine mortality
out_fl(C)=fct(C); % write to output matrix


end % end of function