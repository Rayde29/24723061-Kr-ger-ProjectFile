%% Angle of attack (AOA) response 

omega=40;
I=0.001178279;
Matrix = zeros(1,100)
k= 1

nat_freq= sqrt(k/I);
theta_req = 8.*pi/180
theta_default = 5.*pi/180;      % Offset of graph (oscillates around theta default rather than 0)
t= pi/(2.*omega)

% M = (theta_req - theta_default.*cos(nat_freq.*t))/(1/(omega.^2.*I+k)-sin(nat_freq.*t)./((omega.^2.*I+k).*(nat_freq))) 
M = (theta_req-theta_default)/(1/(omega.^2.*I+k)-sin(nat_freq.*t)./((omega.^2.*I+k).*(nat_freq))); 
% theta = @(x) -M/((omega.^2.*I+k).*(nat_freq)).*sin(nat_freq.*x) +theta_default.*cos(nat_freq.*x) + M/(omega.^2.*I+k).*sin(omega.*x)
theta = @(x) -M/((omega.^2.*I+k).*(nat_freq)).*sin(nat_freq.*x) + M/(omega.^2.*I+k).*sin(omega.*x) + theta_default;

x=0:0.001:2;
y=theta(x);
plot(x,y)
xlabel('Time [s]');
ylabel('AOA [rads]');
title('AOA vs time');
xline(2.*pi/omega/4, '--r', 'LineWidth', 1.5);

fplot(@(x) M.*sin(x.*omega)/0.3,[0:1])

%%
k= 1
theta_req = 8.*pi/180
theta_default = 5.*pi/180; 
theta_prev = 0;
M = k.*(theta_req - (theta_prev).*cos(nat_freq.*t))./(1-cos(nat_freq.*t))
theta2= @(x) (theta_prev-M/k).*cos(nat_freq.*x) + M/k
theta2(x)

fplot(theta2,0:1)
xline(2.*pi/30/4, '--r', 'LineWidth', 1.5);

% Critically Damped

k=00.01
theta_req = 8.*pi/180
theta_default = 5.*pi/180; 
t= pi/(2.*omega)*100

% M = k.* (theta_req - theta_prev.*exp(-nat_freq.*t).*(1+nat_freq.*t))./(1+(-1-nat_freq.*t).*exp(-nat_freq.*t)) 
M = k.* theta_req
c=2*sqrt(k.*I)
theta_damped = @(x) (theta_prev- M/k).*(1 + nat_freq.*x).*exp(-nat_freq.*x) + M/k
theta_damped(t)
fplot(theta_damped,0:1)
xlabel('Time [s]');
ylabel('AOA [rads]');
title(['Step input of: ', num2str(M),' Nm']);
xline(2.*pi/30/4, '--r', 'LineWidth', 1.5);
% Under Damped

theta_req =10.*pi/180
k=01
% c=2*sqrt(k.*I);
C= 0.01
theta_prev = 5.*pi/180
T= pi/(2.*omega)


damping_ratio = C./(2.*sqrt(k.*I))
wd = nat_freq.*sqrt(1-damping_ratio.^2)
phi = atan(wd./((damping_ratio.*nat_freq)))
M = theta_req.*k
A = (theta_prev - M/k)./sin(phi)

theta_underdamped = @(x) A.*exp(-damping_ratio.*nat_freq.*x) .* sin(wd.*x + phi) + M/k
fplot(theta_underdamped,0:1)
xline(2.*pi/30/4, '--r', 'LineWidth', 1.5);
xline(2.*pi/30/2, '--b', 'LineWidth', 1.5);
xlabel('Time [s]');
ylabel('AOA [rads]');
title(['Step input of: ', num2str(M),' Nm']);
spring_mat =zeros(1,681);
damp_mat =zeros(1,681);
spring_damping = zeros(68,68);
% Under Damped sinusoidal input

omega = 60

theta_req = 5.*pi/180

for damping =  0.1:1:68.1
    for spring = 0.1:1:68.1
    k= spring/10;
    c=2*sqrt(k.*I);
    C= c-0.005;
    % C=.05
    C= damping/1000;
    % C=0.01
    theta_prev = 0;
        
    T= pi/(2.*omega);
    nat_freq= sqrt(k/I);
    M=1;
    damping_ratio = C./(2.*sqrt(k.*I));
    wd = nat_freq.*sqrt(1-damping_ratio.^2);
    % phi = atan(wd./((damping_ratio.*nat_freq)))
    % M = theta_req.*k
    % A = (theta_prev - M/k)./sin(phi
    for i = 1:2
    X = (M./I)./(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    beta = atan( (2 .* damping_ratio .* nat_freq .* omega )./(nat_freq.^2 - omega.^2));
    
    phi = atan((wd.*(theta_prev- X.*cos(beta)))./((theta_prev-X.*cos(beta)).*damping_ratio.*nat_freq - omega.*X.*cos(beta)));
    A = (theta_prev -X.*cos(beta))/sin(phi);
    
    
    X_M = (theta_req - ((exp(-damping_ratio.*nat_freq.*T).*(theta_prev.*sin(wd.*T + phi)))./sin(phi)))./(cos(omega.*T - beta) - (exp(-damping_ratio.*nat_freq.*T)).*(cos(beta).*sin(wd.*T + phi))./sin(phi));
    M = (X_M.*I).*(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    
    X = (M./I)./(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    M = (X_M.*I).*(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    
    X = (M./I)./(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    beta = atan( (2 .* damping_ratio .* nat_freq .* omega )./(nat_freq.^2 - omega.^2));
    phi = atan((wd.*(theta_prev- X.*cos(beta)))./((theta_prev-X.*cos(beta)).*damping_ratio.*nat_freq - omega.*X.*cos(beta)));
    A = (theta_prev -X.*cos(beta))/sin(phi);
    end
    X_M =theta_req;
    M = (X_M.*I).*(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    X = (M./I)./(sqrt((nat_freq.^2 - omega.^2).^2 + (2 .* damping_ratio .* nat_freq .* omega ).^2));
    
    spring/0.1;
    ceil(spring/0.1);
    % spring_mat(spring-0.1) = M;
    spring_damping(damping-0.1+1,spring-0.1+1) = M;
    end
end

theta_underdamped = @(x) A.*exp(-damping_ratio.*nat_freq.*x) .* sin(wd.*x + phi) + X.*cos(omega.*x - beta)
x=0:0.001:2;
y=theta_underdamped(x);
plot(x,y)
xlabel('Time [s]');
ylabel('AOA [rads]');
title(['X cos(omega*t) with X of ', num2str(M),' Nm']);
xline(2.*pi/30/4, '--r', 'LineWidth', 1.5);
xline(2.*pi/30/2, '--b', 'LineWidth', 1.5);
shg
%%
spring_damping(1,:)
plot(0.1:0.1:68.1,spring_mat)
surf(spring_damping)