%--------------------------------------------------------------------------
%------  Analysis tool for MCTDHB calculations 
%------ (Time dependend density)
%------  J. Schurer 18.02.2018
%--------------------------------------------------------------------------
clear all

%----What data  to get ?
%mysqlitecommand = {'g=1 AND N=10','system=''LLP'' AND method=''relax'''};
mysqlitecommand = {'omega IN (20,40,60,80)','RunNumber=''run634_N1_local_0.5'''};
%mysqlitecommand = {'m_I IN (4,6,8,9)','RunNumber=''run636_local_lI_0.5_largeM'''};

folder = DataBase.myDataBase('myDB', 'getFolder', mysqlitecommand);
if isempty(folder) error('NO DATA FOUND'); end


dof = 1;
node = 3;

redo = 0;
plotStyle = 0;
ratio = length(folder)/3;

equalRange = 1;
crange=[ 0.0 1.0 ]; %[ ];%
endTime=0;  % Put 0 for full range
logplt = 0;
ymin = 1e-5;

minZ = -5;
maxZ = 5;

colorplot = 1;
lineplot = ~colorplot;


%% Collect data
for jj=1:length(folder)
    params{jj} = Scripts.GetData( folder{jj,1}, 'params' ,redo, [], [] );
    gpop{jj} = Scripts.GetData( folder{jj,1}, 'gpop' ,redo, [], [] );
    grids{jj} = eval(['gpop{jj}.grid' int2str(dof) ]);
    gpopDens{jj} =  eval(['gpop{jj}.dof' int2str(dof) ]);
    time{jj} =  gpop{jj}.time;
    
    natpop{jj} = Scripts.GetData( folder{jj,1}, 'natpop' ,redo, [], [] );
    npop{jj} = eval(['natpop{jj}.node' int2str(node) ])./1000;
    %norb{jj} = Scripts.GetData( folder{jj,1}, 'natorb' ,redo, [dof, 100, 0], [] );
    time{jj} =  natpop{jj}.time;
end

plotdata =  gpopDens;%npop; %

%% PLOT data

figure(10)
clf
hold on
nOfPoints=2000;
if colorplot
    colors = colormap(Scripts.cubehelix(nOfPoints,1.11,0.05,2.6,0.5));
else
    colors = colormap(lines(20));
end

for jj=1:length(folder)
    
    subplot(length(folder),1,jj)
    
    if colorplot
        
        if logplt
            I = imagesc(time{jj},grids{jj},log(abs(plotdata{jj}))');
        else
            I = imagesc(time{jj},grids{jj},abs(plotdata{jj})');
        end
        
        set(gca,'YDir','normal')
        if equalRange
            caxis(crange)
        else
             h = colorbar;
             %set(h, 'Yscale', 'log');
             ylabel(h,'$\rho(z)/N$ (units of $1/R^*$)');
        end

        ylabel('$z$ (units of $R^*$)');
        ylim([ minZ maxZ])

    
    elseif lineplot
        hold on
        for kk=1:size(plotdata{jj},2)
           p=plot(time{jj},plotdata{jj}(:,kk));
           set(p, 'Color', colors(kk,:)); 
        end
        
        ylabel('$\lambda_j/N$');
        box on
        if logplt 
           set(gca,'YScale','log') 
           ylim([ymin 2])
           grid on
        end   
    end     
    
    title(folder{jj}(strfind(folder{jj},'run'):end))
    xlabel('$t$ (units of $\hbar/E^*$)');
    if endTime == 0
      xlim([ min(time{jj}) max(time{jj})])
    else    
      xlim([ min(time{jj}) endTime])
    end
end    
hold off

Scripts.qfst(gcf, [ 'data1/density(t)_dof' num2str(dof)  ],ratio,plotStyle)