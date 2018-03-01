function [] = qfst (figH , name, ratio, style)
%qfst Make figure nice and Save it
%   Change figure such that it looks nice 
%--------------------------------------------------------------------------
%------  Quick figure set tool
%------  J. Schurer 14.7.2014
%--------------------------------------------------------------------------
%------ @in figH: figure handle to figure which needs to be set
%------ @in name: name of the figure to save (can contain folder string)
%------ @in style: 0 = normal , 1 = small for paper
%--------------------------------------------------------------------------

if style == 0 
    labelSize = 16;
    tickSize = 14;
    width = 16; %cm
    interP = 'latex';
    lineSize = 2;
    markerSize=10;
elseif style == 1
    labelSize = 8;
    tickSize = 6;
    width = 8.5; % figure width for APS 8.5 cm 
    interP = 'latex';
    lineSize = 0.5;
    markerSize=4;
elseif style == 2
    labelSize = 16;
    tickSize = 14;
    width = 16*2; %cm
    interP = 'latex';
    lineSize = 2;
    markerSize=10;
elseif style == 3
    labelSize = 24;
    tickSize = 18;
    width = 8.5; % figure width for APS 8.5 cm 
    interP = 'latex';
    lineSize = 4.0;
    markerSize=10;
elseif style == 4
    labelSize = 16;
    tickSize = 14;
    width = 8; % figure width for APS 8.5 cm 
    interP = 'latex';
    lineSize = 2.0;
    markerSize=10;
else
    error('qfst','Style not choosen correctly')
end

% Iterate over all Axes in this figure
allAxesInFigure = findall(figH,'type','axes');
numAxes = length(allAxesInFigure);
for j=1:numAxes
    currAx = allAxesInFigure(j);
    
    hAxLabL = get(currAx,{'XLabel' 'YLabel'}); 
    set(hAxLabL{1},'FontSize',labelSize,'Interpreter',interP)
    set(hAxLabL{2},'FontSize',labelSize,'Interpreter',interP)
    
    if strcmp(get(currAx,'Tag') , 'legend')
        set(currAx,'FontSize',labelSize)
        set(currAx,'Interpreter',interP)
        set(currAx,'Box','off')
        if style == 1 
            set(currAx,'Visible','on')
            set(currAx,'Visible','off')
        end
    else
        set(currAx,'FontSize',tickSize)
        set(currAx,'Box','on')
        %set(currAx, 'GridLineStyle', 'none');
    end
    
    set(currAx,'Layer','top')

    
    allPlotsInAxes = findall(currAx,'type','line');
    numPlots = length(allPlotsInAxes);
    for jj= 1: numPlots
        currPlot = allPlotsInAxes(jj);
        if get(currPlot,'LineWidth') == 0.5
            set(currPlot,'LineWidth',lineSize,'MarkerSize',markerSize)
        end
    end
    
end

allTextsInFigure = findall(figH,'Type','text') ;
for j=1:length(allTextsInFigure);
    currTx = allTextsInFigure(j);
    if strfind(get(currTx,'String'),'run')
        set(currTx,'FontSize',9,'Interpreter','None')
    else
        set(currTx,'FontSize',labelSize,'Interpreter',interP)
    end
end

pos = get(figH, 'Position');
%ratio = width/pos(3);
pos(3) = width;
pos(4) = width*ratio;
set(figH, 'units', 'centimeters', 'pos', pos)

set(figH, 'Renderer', 'painter');
set(figH, 'PaperPositionMode','auto'),
set(figH, 'PaperOrientation','portrait');
print(figH,'-depsc ','-loose',[ name '.eps'])
