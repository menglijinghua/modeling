function res = genetic_algorithm(varargin)

% Initialize default configuration
defaultConfig.xy          = 10*rand(40,2);
defaultConfig.dmat        = [];  % N*N距离矩阵
defaultConfig.nSalesmen   = 8;
defaultConfig.minTour     = 3;
defaultConfig.popSize     = 80;
defaultConfig.numIter     = 5e3;
defaultConfig.showProg    = true;
defaultConfig.showResult  = true;
defaultConfig.showWaitbar = false;

% Interpret user configuration inputs
if ~nargin
    userConfig = struct();
elseif isstruct(varargin{1})
    userConfig = varargin{1};
else
    try
        userConfig = struct(varargin{:});
    catch
        error('Expected inputs are either a structure or parameter/value pairs');
    end
end

% Override default configuration with user inputs
configStruct = configuration(defaultConfig,userConfig);

% Extract configuration
xy          = configStruct.xy;
dmat        = configStruct.dmat;
nSalesmen   = configStruct.nSalesmen;
minTour     = configStruct.minTour;
popSize     = configStruct.popSize;
numIter     = configStruct.numIter;
showProg    = configStruct.showProg;
showResult  = configStruct.showResult;
showWaitbar = configStruct.showWaitbar;
if isempty(dmat)
    nPoints = size(xy,1);
    a = meshgrid(1:nPoints);
    dmat = reshape(sqrt(sum((xy(a,:)-xy(a',:)).^2,2)),nPoints,nPoints);
end

% Verify Inputs 验证输入
[N,dims] = size(xy);
[nr,nc] = size(dmat);
if N ~= nr || N ~= nc
    error('Invalid XY or DMAT inputs!')
end
n = N - 1; % Separate Start/End City

% Sanity Checks
nSalesmen   = max(1,min(n,round(real(nSalesmen(1)))));
minTour     = max(1,min(floor(n/nSalesmen),round(real(minTour(1)))));
popSize     = max(8,8*ceil(popSize(1)/8));
numIter     = max(1,round(real(numIter(1))));
showProg    = logical(showProg(1));
showResult  = logical(showResult(1));
showWaitbar = logical(showWaitbar(1));

% Initializations for Route Break Point Selection 路径断点选择的初始化
nBreaks = nSalesmen-1;
dof = n - minTour*nSalesmen;          % degrees of freedom
addto = ones(1,dof+1);
for k = 2:nBreaks
    addto = cumsum(addto);
end
cumProb = cumsum(addto)/sum(addto);

% Initialize the Populations
popRoute = zeros(popSize,n);         % population of routes
popBreak = zeros(popSize,nBreaks);   % population of breaks
popRoute(1,:) = (1:n) + 1;
popBreak(1,:) = rand_breaks();
for k = 2:popSize
    popRoute(k,:) = randperm(n) + 1;
    popBreak(k,:) = rand_breaks();
end

% Select the Colors for the Plotted Routes    所画路径的颜色
pclr = ~get(0,'DefaultAxesColor');
clr = [1 0 0; 0 0 1; 0.67 0 1; 0 1 0; 1 0.5 0];
if nSalesmen > 5
    clr = hsv(nSalesmen);
end

% Run the GA
globalMin = Inf;
totalDist = zeros(1,popSize);
distHistory = zeros(1,numIter);
tmpPopRoute = zeros(8,n);
tmpPopBreak = zeros(8,nBreaks);
newPopRoute = zeros(popSize,n);
newPopBreak = zeros(popSize,nBreaks);
if showProg
    figure('Name','MTSPF_GA | Current Best Solution','Numbertitle','off');
    hAx = gca;
end
if showWaitbar
    hWait = waitbar(0,'Searching for near-optimal solution ...');
end
for iter = 1:numIter
    % Evaluate Members of the Population    人口评估
    for p = 1:popSize
        d = 0;
        pRoute = popRoute(p,:);
        pBreak = popBreak(p,:);
        rng = [[1 pBreak+1];[pBreak n]]';
        for s = 1:nSalesmen
            d = d + dmat(1,pRoute(rng(s,1))); % Add Start Distance
            for k = rng(s,1):rng(s,2)-1
                d = d + dmat(pRoute(k),pRoute(k+1));
            end
            d = d + dmat(pRoute(rng(s,2)),1); % Add End Distance
        end
        totalDist(p) = d;
    end
    
    % Find the Best Route in the Population
    [minDist,index] = min(totalDist);
    distHistory(iter) = minDist;
    if minDist < globalMin
        globalMin = minDist;
        optRoute = popRoute(index,:);
        optBreak = popBreak(index,:);
        rng = [[1 optBreak+1];[optBreak n]]';
        if showProg
            % Plot the Best Route   实时展示最优路径
            for s = 1:nSalesmen
                rte = [1 optRoute(rng(s,1):rng(s,2)) 1];
                if dims > 2, plot3(hAx,xy(rte,1),xy(rte,2),xy(rte,3),'.-','Color',clr(s,:));
                else plot(hAx,xy(rte,1),xy(rte,2),'.-','Color',clr(s,:)); end
                hold(hAx,'on');
            end
            if dims > 2, plot3(hAx,xy(1,1),xy(1,2),xy(1,3),'o','Color',pclr);
            else plot(hAx,xy(1,1),xy(1,2),'o','Color',pclr); end
            title(hAx,sprintf('Total Distance = %1.4f, Iteration = %d',minDist,iter));
            hold(hAx,'off');
            drawnow;
        end
    end
    
    % Genetic Algorithm Operators
    randomOrder = randperm(popSize);
    for p = 8:8:popSize
        rtes = popRoute(randomOrder(p-7:p),:);
        brks = popBreak(randomOrder(p-7:p),:);
        dists = totalDist(randomOrder(p-7:p));
        [ignore,idx] = min(dists); %#ok
        bestOf8Route = rtes(idx,:);
        bestOf8Break = brks(idx,:);
        routeInsertionPoints = sort(ceil(n*rand(1,2)));
        I = routeInsertionPoints(1);
        J = routeInsertionPoints(2);
        for k = 1:8 % Generate New Solutions
            tmpPopRoute(k,:) = bestOf8Route;
            tmpPopBreak(k,:) = bestOf8Break;
            switch k
                case 2 % Flip
                    tmpPopRoute(k,I:J) = tmpPopRoute(k,J:-1:I);
                case 3 % Swap
                    tmpPopRoute(k,[I J]) = tmpPopRoute(k,[J I]);
                case 4 % Slide
                    tmpPopRoute(k,I:J) = tmpPopRoute(k,[I+1:J I]);
                case 5 % Modify Breaks
                    tmpPopBreak(k,:) = rand_breaks();
                case 6 % Flip, Modify Breaks
                    tmpPopRoute(k,I:J) = tmpPopRoute(k,J:-1:I);
                    tmpPopBreak(k,:) = rand_breaks();
                case 7 % Swap, Modify Breaks
                    tmpPopRoute(k,[I J]) = tmpPopRoute(k,[J I]);
                    tmpPopBreak(k,:) = rand_breaks();
                case 8 % Slide, Modify Breaks
                    tmpPopRoute(k,I:J) = tmpPopRoute(k,[I+1:J I]);
                    tmpPopBreak(k,:) = rand_breaks();
                otherwise % Do Nothing
            end
        end
        newPopRoute(p-7:p,:) = tmpPopRoute;
        newPopBreak(p-7:p,:) = tmpPopBreak;
    end
    popRoute = newPopRoute;
    popBreak = newPopBreak;
    
    % Update the waitbar
    if showWaitbar && ~mod(iter,ceil(numIter/325))
        waitbar(iter/numIter,hWait);
    end
    
end
if showWaitbar
    close(hWait);
end

if showResult
    % Plots     画图
    %     figure('Name','MTSPF_GA | Results','Numbertitle','off');
    %     subplot(2,2,1);
    %     if dims > 2, plot3(xy(:,1),xy(:,2),xy(:,3),'.','Color',pclr);
    %     else plot(xy(:,1),xy(:,2),'.','Color',pclr); end
    %     title('City Locations');
    %     subplot(2,2,2);
    %     imagesc(dmat([1 optRoute],[1 optRoute]));
    %     title('Distance Matrix');
    %     subplot(2,2,3);
    %     rng = [[1 optBreak+1];[optBreak n]]';
    %     for s = 1:nSalesmen
    %         rte = [1 optRoute(rng(s,1):rng(s,2)) 1];
    %         if dims > 2, plot3(xy(rte,1),xy(rte,2),xy(rte,3),'.-','Color',clr(s,:));
    %         else plot(xy(rte,1),xy(rte,2),'.-','Color',clr(s,:)); end
    %         title(sprintf('Total Distance = %1.4f',minDist));
    %         hold on;
    %     end
    %     if dims > 2, plot3(xy(1,1),xy(1,2),xy(1,3),'o','Color',pclr);
    %     else plot(xy(1,1),xy(1,2),'o','Color',pclr); end
    %     subplot(2,2,4);
    %     plot(distHistory,'b','LineWidth',2);
    %     title('Best Solution History');
    %     set(gca,'XLim',[0 numIter+1],'YLim',[0 1.1*max([1 distHistory])]);
    %     figure('Name','MTSPF_GA | Results','Numbertitle','off');
    figure(1)
    plot(xy(1,1),xy(1,2),'.','Color',[1,0,1],'MarkerSize',20);
    hold on
    text(xy(1,1),xy(1,2),'数据中心','Color','b');
    for i=2:30
        plot(xy(i,1),xy(i,2),'.','Color','r','MarkerSize',15);
        hold on
        text(xy(i,1),xy(i,2),['传感器',num2str(i-1)],'Color','b');
    end
    if dims > 2, plot3(xy(:,1),xy(:,2),xy(:,3),'.','Color',pclr);
    else plot(xy(:,1),xy(:,2),'.','Color',pclr); end
    xlabel('经度');
    ylabel('纬度');
    title('数据中心和传感器的分布图');
%     figure(2)
%     imagesc(dmat([1 optRoute],[1 optRoute]));
%     xlabel('经度');
%     ylabel('纬度');
%     title('Distance Matrix');
    figure(3)
    plot(xy(1,1),xy(1,2),'.','Color',[1,0,1],'MarkerSize',20);
    hold on
    text(xy(1,1),xy(1,2),'数据中心','Color','b');
    for i=2:30
        plot(xy(i,1),xy(i,2),'.','Color','r','MarkerSize',15);
        hold on
        text(xy(i,1),xy(i,2),['传感器',num2str(i-1)],'Color','b');
    end
    xlabel('经度');
    ylabel('纬度');
    rng = [[1 optBreak+1];[optBreak n]]';
    for s = 1:nSalesmen
        rte = [1 optRoute(rng(s,1):rng(s,2)) 1];
        if dims > 2, plot3(xy(rte,1),xy(rte,2),xy(rte,3),'.-','Color',clr(s,:));
        else plot(xy(rte,1),xy(rte,2),'.-','Color',clr(s,:)); end
        %         title(sprintf('Total Distance = %1.4f',minDist));
        title('移动路线图');
        hold on;
    end
    if dims > 2, plot3(xy(1,1),xy(1,2),xy(1,3),'o','Color',pclr);
    else plot(xy(1,1),xy(1,2),'o','Color',pclr); end
    figure(4)
    plot(distHistory,'b','LineWidth',2);
    title('Best Solution History');
    set(gca,'XLim',[0 numIter+1],'YLim',[0 1.1*max([1 distHistory])]);
end

% Return Output
if nargout
    resultStruct = struct( ...
        'xy',          xy, ...
        'dmat',        dmat, ...
        'nSalesmen',   nSalesmen, ...
        'minTour',     minTour, ...
        'popSize',     popSize, ...
        'numIter',     numIter, ...
        'showProg',    showProg, ...
        'showResult',  showResult, ...
        'showWaitbar', showWaitbar, ...
        'optRoute',    optRoute, ...
        'optBreak',    optBreak, ...
        'minDist',     minDist);
    
    res = {resultStruct};
end
    function breaks = rand_breaks()
        if minTour == 1 % No Constraints on Breaks
            tmpBreaks = randperm(n-1);
            breaks = sort(tmpBreaks(1:nBreaks));
        else % Force Breaks to be at Least the Minimum Tour Length
            nAdjust = find(rand < cumProb,1)-1;
            spaces = ceil(nBreaks*rand(1,nAdjust));
            adjust = zeros(1,nBreaks);
            for kk = 1:nBreaks
                adjust(kk) = sum(spaces == kk);
            end
            breaks = minTour*(1:nBreaks) + cumsum(adjust);
        end
    end
optRoute=optRoute-1;
end