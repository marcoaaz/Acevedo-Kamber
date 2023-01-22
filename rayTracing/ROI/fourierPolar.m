function [results, y_angle] = fourierPolar(x1_sg, model, extra)
%produces a function that can be evaluated by the orientation variable

names = coeffnames(model);
val = coeffvalues(model);

%Conversion
idx_ini = 2;
gamma_zero = val(1);
phi_one = atan2(val(idx_ini+1), val(idx_ini)); %[–π, π] result
gamma_one = sqrt(val(idx_ini)^2 + val(idx_ini+1)^2);

idx_ini = idx_ini + 2;
phi_two = atan2(val(idx_ini+1), val(idx_ini));
gamma_two = sqrt(val(idx_ini)^2 + val(idx_ini+1)^2);
w = val(idx_ini + 2);

angle = sym('angle');
y_angle = gamma_zero + gamma_one*cos(w*angle - phi_one) + gamma_two*cos(2*w*angle - phi_two);

results = subs(y_angle, angle, x1_sg + extra); %substitutes the angle by modified one
results = double(results);

end