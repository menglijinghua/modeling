function [U1,R1]=fun1(distance_,U0,judge,w_,lambda_)
X_max=0.00015;
velocity=70/60;
distance=distance_;
T_max=distance/velocity;
dt=1e-3; %时间步长
dx=0.000001;
w=w_;
lambda=lambda_;
X=ceil(X_max/dx);
T=ceil(T_max/dt);
U=zeros(X,T);
U(:,1)=U0;
for j=1:T-1
    for i=2:X-1
        U(i,j+1)=(1-2*lambda)*U(i,j)+lambda*(U(i+1,j)+U(i-1,j));
    end
    if judge==1
        T0=25+7*j*dt;
    elseif judge==2
        T0=175;
    elseif judge==3
        T0=175+(14/3)*j*dt;
    elseif judge==4
        T0=195;
    elseif judge==5
        T0=195+(28/3)*j*dt;
    elseif judge==6
        T0=235;
    elseif judge==7
        T0=235+(14/3)*j*dt;
    elseif judge==8
        T0=255;
    elseif judge==9
        T0=255-(161/3)*j*dt;
    elseif judge==10
        T0=25;
    elseif judge==11
        T0=25;
    end
    if judge==11||judge==12
        U(1,j+1)=25+(U(1,j)-25)*exp(1)^(-dt/w);
        U(X,j+1)=25+(U(X,j)-25)*exp(1)^(-dt/w);
    else
        U(1,j+1)=(dx*T0+w*U(2,j+1))/(dx+w);
        U(X,j+1)=(dx*T0+w*U(X-1,j+1))/(dx+w);
    end
end
U1=U(:,T);
R1=U(X/2,1:floor(0.5/dt):end);