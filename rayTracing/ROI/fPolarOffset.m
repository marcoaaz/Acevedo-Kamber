function [original, modelPolar, ppl_max_calc, shifted] = fPolarOffset(x1_sg, model_st)
%This function uses PPL and XPL data to infer the PPL peak and phase of the
%fitted Sin curve using the model in polar coordinates. It outputs the
%shifted versions of the curves to make them comparable.

model1 = model_st.ppl_model;
model2 = model_st.xpl_model;

%[results, y_angle] = fourierPolar(x1_sg, model, extra) %extra= added phase
results1 = fourierPolar(x1_sg, model1, 0); 
results2 = fourierPolar(x1_sg, model2, 0);

%Sub-optimal finding of PPL-max (not interpolated)
[~, idx1] = min(results1);
[~, idx2] = max(results1);
[~, idx3] = min(results2);
[~, idx4] = max(results2);
ppl_min = x1_sg(idx1); 
ppl_max = x1_sg(idx2); 
xpl_min = x1_sg(idx3); 
xpl_max = x1_sg(idx4); 

%Criteria
ppl_avg = (ppl_min + ppl_max)/2;
xpl_min_calc = (xpl_min + min(ppl_min, ppl_max))/2; %due to XPL constraints
% xpl_max_calc = (xpl_max + min(ppl_avg, ppl_avg-90))/2; %optional

%Peak phase (two possible xpl_min can correspond to ppl_max)
a = fourierPolar(xpl_min_calc, model1, 0);
b = fourierPolar(xpl_min_calc+90, model1, 0);
if a>b
    ppl_max_calc = xpl_min_calc;
elseif a<b
    ppl_max_calc = xpl_min_calc + 90;
end

%Shifted PPL-max
[shift1, y_angle1] = fourierPolar(x1_sg, model1, ppl_max_calc);
[shift2, y_angle2] = fourierPolar(x1_sg, model2, ppl_max_calc);

original{1} = results1;
original{2} = results2;
shifted{1} = shift1;
shifted{2} = shift2;
modelPolar{1} = y_angle1;
modelPolar{2} = y_angle2;

end