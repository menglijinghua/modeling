function [forecast,relative_error]=Verhulst(A)
% A=[24 26 26 26 27 27 29 30 30 30 31 31 31 31 34 35 45];

[row,col]=size(A);
if row>col
    A=A';
end
n = length(A);%A的长度
%对原始A 做累减得到数列Y
for i = 2:n
    Y(i) = A(i) - A(i - 1);
end
Y(1) = [];
%对原始数列 A 做紧邻均值生成
for i = 2:n
    z(i) = (A(i) + A(i-1))/2;
end
z(1) = []; 
B = [-z; z.^2];
Y = Y';
%使用最小二乘法计算参数
u = inv(B*B')*B*Y;
u = u';
a = u(1); b = u(2);
%预测数据
F = []; F(1) = A(1);
for i = 2:(2*n)
    F(i) = (a*A(1))/(b*A(1)+(a - b*A(1))*exp(a*(i-1)));
end
forecast=F;
relative_error=abs(A(1:n)-F(1:n))./A(1:n);
