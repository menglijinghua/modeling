clc;clear;
data=xlsread('C题附件2.xlsx');
L=11844.5363; %第一问求出来的路线总距离
n1=[2 1 9 7 6 11 14 15 27 16 13 12 8 10 5 3 ...
    4 22 28 24 23 21 29 26 25 18 19 20 17];%第一问求出来的路线
n2=fliplr(n1);%第一问求出来的反方向路线
Q=zeros(29,2);
Q(:,1)=fun2(n1,data,L);
Q(:,2)=fun2(n2,data,L);

