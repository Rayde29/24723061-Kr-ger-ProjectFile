%% Rotor
% 

theta = 5;
alpha = 5;
rho = 1.225;

R = 0.4;    %Rotor Radius
c=0.15;     %Rotor Chord
V1 = 0;     

B = 2;      %Number of blades
segments = 250;
r_seg = 0:R/segments:R;

torque_profile = zeros(1,length(r_seg));
thrust_profile = zeros(1,length(r_seg));
V0 = zeros(1,length(r_seg));
F= 0.05;
iterations = 3;     % Number of interation for the V01 
torque_P = zeros (iterations,length(r_seg));  
thrust_P = zeros (iterations,length(r_seg));
vortex_strength = zeros (iterations,length(r_seg));
vortex_tangentail_velcoity = zeros (1,length(r_seg));
total_torque = 0;
Torque_thrust = F*R*2;
torque_speed_curve = zeros (1,800/10);
thrust_speed_curve = zeros (1,800/10);

% omega = Omega_Estimate(Cl(alpha),rho,Torque_thrust,c,theta-alpha,Cd(alpha), B,V0(end),.69349*R)

for x = 10:10:800 % For loop to get thrust produceed for different omega values 
   
    omega = x;
    thrust_profile = zeros(1,length(r_seg));
    V02 = 0;
    for j = 1:iterations
    alpha = theta - atand(V02./length(r_seg)/(3./4.*R.*omega));

    for i = 1:length(r_seg)

        thrust_profile(i) = Thrust(Cl(alpha),rho,omega,r_seg(i),c,theta-alpha,Cd(alpha), B,V0(i),R/segments) * 0.98; % *0.98 to help account for Tip vortices
        torque_profile(i) = Torque(Cl(alpha),rho,omega,r_seg(i),c,theta-alpha,Cd(alpha), B,V0(i),R/segments);
        thrust_P(j,i)=thrust_profile(i);
        torque_P(j,i)=torque_profile(i);
    
    end

    total_thrust = sum(thrust_profile(4:end));
    total_torque = sum(torque_profile(4:end));
    V02 = sqrt(total_thrust/(pi * R.^2 .* rho));

    end
  
    torque_speed_curve((x/10)) = total_torque;
    thrust_speed_curve((x/10)) = total_thrust;

end

plot(r_seg(4:end),torque_P(1,4:end))
xlabel('Radius [m]');
ylabel('Torque [Nm]');
title(['Total Torque: ', num2str(total_torque)]);

plot(r_seg(4:end),thrust_P(end,4:end)) 
xlabel('Radius [m]');
ylabel('Thrust [N]');
title(['Total Thrust: ', num2str(total_thrust)]);
alpha
plot((10:10:800),torque_speed_curve)
title("Speed Curve Torque")
xlabel('Angular Velocity [rad/s]');
ylabel('Torque [Nm]');

plot((10:10:800),thrust_speed_curve)
title("Speed Curve Thrust")
xlabel('Angular Velocity [rad/s]');
ylabel('Thrust [Nm]');

%% Angle of attack 

interval =0.5
AOA_Vs_Thrust = zeros(1, 14/interval);
omega_AOA_profile = zeros(1, 8)
for omega = 10:10:100

for AOA = 0:interval:14
    theta = AOA;
    thrust_profile = zeros(1,length(r_seg));
    V02 = 0;
    for j = 1:iterations
    alpha = theta - atand(V02./length(r_seg)/(3./4.*R.*omega));

    for i = 1:length(r_seg)
        thrust_profile(i) = Thrust(Cl(alpha),rho,omega,r_seg(i),c,theta-alpha,Cd(alpha), B,V0(i),R/segments);
        torque_profile(i) = Torque(Cl(alpha),rho,omega,r_seg(i),c,theta-alpha,Cd(alpha), B,V0(i),R/segments);
        thrust_P(j,i)=thrust_profile(i);
        torque_P(j,i)=torque_profile(i);
    end
    total_thrust = sum(thrust_profile(4:end));
    total_torque = sum(torque_profile(4:end));
    V02 = sqrt(total_thrust/(pi * R.^2 .* rho));
    AOA_Vs_Thrust(AOA/interval + 1)=total_thrust;
    end
end

AOA_Vs_Thrust(end)/14;
omega_AOA_profile(omega/10) = (AOA_Vs_Thrust(end))/14;

end
plot(0:interval:14,AOA_Vs_Thrust,'r') 
xlabel('Angle Of Attack [degrees]');
ylabel('Thrust [N]');
title('AOA Vs Thrust');

plot( 10:10:100, omega_AOA_profile)
xlabel('Angular velocity [rad/s]');
ylabel('AOA gradient [degrees]');
title('AOA gradient Vs angular velocity');
%% Propeller

% Prop_radius = 2*0.0254 %From inchs to m
% pitch = 0.0254*1.9
Prop_radius = 0.072/2   %(EFLUP72653BR ) Propeller
pitch = 0.065 ;         %(EFLUP72653BR)
nr_of_blades = 3;
pitch_angle = atand(pitch/(2*Prop_radius*pi))
speed = 800;            % Itterates between  start and speed of omega values
prop_thrust_profile= zeros(1,speed/10);
prop_torque_profile= zeros(1,speed/10);
prop_Thrust_p1_coeffcient = zeros(1,speed/10);
prop_Thrust_p2_coefficient =  zeros(1,speed/10);
prop_Thrust_p3_coeffcient =  zeros(1,speed/10);
all_thrust_profiles = zeros(speed/10,speed/10);
all_torque_profiles = zeros(speed/10,speed/10);

start = 10;
xx = (start:10:speed).*2.*pi


X = [start:10:speed]'.*60;

for Omega_Speed = start:10:speed
for Prop_speeds= start:10:speed
    V0_prop = Omega_Speed.*R;
    Omega_prop = Prop_speeds.*60*pi/30; % Converts speed to have a max of 48 000 rpm then into rad/s
    chord_of_prop = 0.01;               % 1 cm wide props

    phi_prop = atand(V0_prop/(3./4.*Prop_radius.*Omega_prop));  
    
    alpha_prop = pitch_angle - phi_prop;

    thrust_from_prop = Thrust(Cl(alpha_prop),rho,Omega_prop,2/3*Prop_radius,chord_of_prop,phi_prop,Cd(alpha_prop), nr_of_blades,V0_prop,2/3*Prop_radius);
    torque_of_prop = Torque(Cl(alpha_prop),rho,Omega_prop,2/3*Prop_radius,chord_of_prop,phi_prop,Cd(alpha_prop), nr_of_blades,V0_prop,2/3*Prop_radius);
    prop_thrust_profile(Prop_speeds/10) = thrust_from_prop;
    prop_torque_profile(Prop_speeds/10) = torque_of_prop;
    all_thrust_profiles(Omega_Speed/10,Prop_speeds/10)= thrust_from_prop;
    all_torque_profiles(Omega_Speed/10,Prop_speeds/10)= torque_of_prop;

    
end
plot((start:10:speed).*60.*pi/30,prop_thrust_profile)
xlabel('angular velocity [rad/s]');
ylabel('Thrust [N]');
title('Prop thrust for increasing values of Omega');
yline(0, '--r', 'LineWidth', 1.5);

hold on

FO = fit(xx',prop_thrust_profile', 'poly2');    % Fitting the the thrust profile to a polynomial of degeree 2 (ax^2 + bx + c)
prop_Thrust_p1_coeffcient(Omega_Speed/10) = FO.p1;
prop_Thrust_p2_coefficient(Omega_Speed/10) = FO.p2;
prop_Thrust_p3_coeffcient(Omega_Speed/10) = FO.p3;
end
hold off

prop_Thrust_p1_coeffcient;
prop_thrust_profile;

Y=FO(xx);
plot(xx,Y)
xlabel('Angular veloctiy [rpm]');
ylabel('Thrust [N]');
title('Fittied vs actual graph');
hold on
plot((start:10:speed)*60.*pi/30,prop_thrust_profile)
legend(["Fitted Data","Actual Data"])
hold off
plot(start:10:speed,prop_Thrust_p3_coeffcient)
xlabel('Omega');
ylabel('Coeffcient');
title('P3 (in P1(Omega^2) + P2(Omega) + P3) Vs Omega');

plot(start:10:speed,prop_Thrust_p2_coefficient)
xlabel('Omega');
ylabel('Coeffcient');
title('P2 (in P1(Omega^2) + P2(Omega) + P3) Vs Omega');

plot(start:10:speed,prop_Thrust_p1_coeffcient)
xlabel('Omega');
ylabel('Coeffcient');
title('P1 (in P1(Omega^2) + P2(Omega) + P3) Vs Omega');

hold on

FC2 = fit((start:10:speed)',prop_Thrust_p1_coeffcient','poly6')
YY = FC2((start:10:speed)');
plot((start:10:speed)',YY)
legend(["Actual Data","Fitted Data"])
legend("Position", [0.6524,0.15242,0.22179,0.089378])
hold off


%% Curve Fitting

X = [(10:10:800)]';
Thrust_function = fit(X,thrust_speed_curve', 'power1')
Torque_function = fit(X,torque_speed_curve','power1')
prop_A_coef = fit((start:10:speed)',prop_Thrust_p1_coeffcient','poly6');
prop_B_coef = fit((start:10:speed)',prop_Thrust_p2_coefficient','poly6');
prop_C_coef = fit((start:10:speed)',prop_Thrust_p3_coeffcient','poly6');
FO = fit(X.*60,prop_thrust_profile', 'poly2');

%% Speed for thrust calculator

% Enter required thrust below 
Thrust_req = 5

omega_for_thrust = @(x) (x./Thrust_function.a).^(1/Thrust_function.b);              % Converts Thrust to Omega value
Torque_for_thrust = @(x) Torque_function.a.*omega_for_thrust(x).^Torque_function.b; % converts Thrust into torque
Thrust_requried = Torque_for_thrust(Thrust_req)/(2*R);
omega= omega_for_thrust(Thrust_req);
prop_speed_function = @(x) prop_A_coef(omega).*x.^2 + prop_B_coef(omega).*x + prop_C_coef(omega) - Thrust_requried./2;
% fplot(prop_speed_function,[0,5000])
prop_speed =fzero(prop_speed_function,200.*Thrust_req).*30/pi;

fprintf('Rotor speed: %.2f rpm (%.2f rad/s)',omega.*30/pi,omega)
fprintf('Torque required: %.2f Nm',Thrust_requried*(2*R))
fprintf('Thrust required: %.2f N',Thrust_requried)
fprintf('Prop speed: %.2f rpm (%.2f rad/s)',prop_speed, prop_speed.*pi/30)
fprintf('Tip speed: %.2f m/s',omega*R)

% plot(X*pi./30,all_torque_profiles(floor(omega/10),:))
%% 
% 
%% Functions
% Thrust produced

function thrust = Thrust(Cl,rho,omega,r,c,phi,Cd,B,V0,dr_segment)
    V1 = sqrt((omega.*r).^2 + (V0).^2);
    thrust = 1/2 .* rho .* V1.^2 .* (Cl .* cosd(phi) - Cd .* sind(phi)) .* B .* c .* dr_segment;
end
% Torque produced

function torque = Torque(Cl,rho,omega,r,c,phi,Cd,B,V0,dr_segment)
    V1 = sqrt((omega.*r).^2 + (V0).^2);
    torque = 1/2 .* rho .* V1.^2 .* (Cd .* cosd(phi) + Cl .* sind(phi)) .* B .* c .* dr_segment .* r;
end
% Crossectional area

function area_of_NACA = dr(c,t)
    NACA_f = @(x) 5.*t.*(0.2969.*sqrt(x) - 0.126.*x - 0.3156.*x.^2 + 0.2843.*x.^3 - 0.1015.*x.^4);
    area_of_NACA = 2*integral(NACA_f,0,c);
end
% Lift produced for defined alpha

function lift_coefficent = Cl(alpha)
    % lift_coefficent = 1./10 .* alpha + 0;
    lift_coefficent = 3./25 .* alpha + 0.6;

end
% Drag produced for defined alpha

function drag_coeffcient = Cd(alpha)
    % drag_coeffcient = 1.6e-4 .* alpha.^2 +0.005;
    drag_coeffcient = 3.8e-4 .* alpha.^2 +0.02;

end
% Estimate rotational speed to produce a given torque

function omega = Omega_Estimate(Cl,rho,total_drag,c,phi,Cd,B,V0,L)
    V1_squared = 2.* total_drag / (rho * (Cd * cosd(phi) + Cl * sind(phi)) * B * c.*L*L);
    omega = sqrt((V1_squared) - (V0).^2)/(L);
end
% Estimate rotational speed to produce a given thrust


function omega_thrust = Omega_Thrust_Estimate(Cl,rho,total_thrust,c,phi,Cd,B,V0,L,omega)
    V1_squared = 2.* total_thrust / (rho * (Cl * cosd(phi) - Cd * sind(phi)) * B * c *L);
    if V1_squared < V0^2
        omega_thrust =2*omega;
    else
        omega_thrust = sqrt((V1_squared) - (V0).^2)/(L);
    end
end
% Estimate speed of tip thrust for required torque

function Thrust_Requirements(required_thrust,R)
    X = [(10:10:800)]';
    Thrust_function = fit(X,thrust_speed_curve', 'power1')
    Torque_function = fit(X,torque_speed_curve','power1')
    prop_A_coef = fit((start:10:speed)',prop_Thrust_p1_coeffcient','poly6');
    prop_B_coef = fit((start:10:speed)',prop_Thrust_p2_coefficient','poly6');
    prop_C_coef = fit((start:10:speed)',prop_Thrust_p3_coeffcient','poly6');
    FO = fit(X.*60,prop_thrust_profile', 'poly2');


    omega_for_thrust = @(x) (x./Thrust_function.a).^(1/Thrust_function.b);
    Torque_for_thrust = @(x) Torque_function.a.*omega_for_thrust(x).^Torque_function.b;
    omega= omega_for_thrust(Thrust_req);
    omega.*30/pi;
    Thrust_requried = Torque_for_thrust(Thrust_req)/R
    fprintf(['Speed in RPM:%.2f \n',omega.*30/pi ...
        'Thrust required:%.2f',Thrust_requried])
    prop_speed_function = @(x) prop_A_coef(omega).*x.^2 + prop_B_coef(omega).*x + prop_C_coef(omega) - Thrust_requried;
    % fplot(prop_speed_function,[0,5000])
    fzero(prop_speed_function,3000).*30/pil
end