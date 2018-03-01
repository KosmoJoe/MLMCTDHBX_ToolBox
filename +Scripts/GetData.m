%--------------------------------------------------------------------------
%------  Load or create data for MCTDHB calculations 
%------  General Read In TOOL
%------  J. Schurer 10.03.2016
%--------------------------------------------------------------------------

function [ data ] = GetData( folder, type ,redo, numargs, strargs )
%GetData: Function which returns MCTDHX data by running analysis tasks and
%doing binary conversion via OutputSTD.py
% INPUTS:
%  @in folder: folder where the data is stored
%  @in type:   data you want to get (see below)
%  @in redo:   specify if the analysis and conversion should be redone (e.g. when run was continued)
%  @in numargs: list of nummeric arguments whose meaning is specified for each type
%  @in strargs: list of string arguments whose meaning is specified for each type
%
%  @out data: container of the data specified by type 

if ~exist('folder','var'), error('No Input Folder given'); end   
if ~exist('type','var'), error('No Input Type given'); end
if ~exist('redo','var'), redo=0; end
if ~exist('help','var'), help='WTF'; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EXPLANATION OF CASES
%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  type = 
%%%
%-----------------------------------------------------------------------
%%%  'params': get the parameters 
%%%
%%%             ## --> GetData( folder, 'params' ,redo, [], {} );  
%-----------------------------------------------------------------------
%%%  'output': get the content of the output file
%%%
%%%             ## --> GetData( folder, 'output' ,redo, [], {} );  
%-----------------------------------------------------------------------
%%%  'gpop':   get the gpop (one-body densities) for all DOFs
%%%
%%%             ## --> GetData( folder, 'gpop' ,redo, [], {} );  
%-----------------------------------------------------------------------
%%%  'natpop': get the natural populations for all nodes
%%%
%%%             ## --> GetData( folder, 'natpop' ,redo, [], {} );  
%-----------------------------------------------------------------------
%%%  'natorb': get the natural orbitals of degree of freedom (dof) at every
%%%            xtimestep (xend = 0) or only the last time (xend = 1)
%%%
%%%             ## --> GetData( folder, 'natorb' ,redo, [dof xtimestep, xend ], [] ); 
%-----------------------------------------------------------------------
%%%  'psi':    get the full psi file (optionally give psifilename)
%%%
%%%             ## --> GetData( folder, 'psi' ,redo, [], {psiFileName} ); 
%-----------------------------------------------------------------------
%%%  'expect': get an expectation value of an operator specified in
%%%            operFileName.py which becomes stored in op_opername
%%%
%%%             ## --> GetData( folder, 'expect' ,redo, [], {operFileName, opername} ); 
%-----------------------------------------------------------------------
%%%  'dmat':   get the one-body density matrices of degree of freedom dof
%%%            at every xtimestep.
%%%             ## --> GetData( folder, 'dmat' ,redo, [dof, xtimestep], {} ); 
%-----------------------------------------------------------------------
%%%  'dmat2':  get the two-body densities between dof1 and dof2 at every
%%%            xtimestep (xend = 0) or at the last time (xend = 1).
%%%
%%%             ## --> GetData( folder, 'dmat2' ,redo, [dof1, dof2, xtimestep, xend], {} ); 
%-----------------------------------------------------------------------
%%%  'fixB':   make a fix basis analysis using the SPFs given in
%%%            restart.ini
%%%
%%%             ## --> GetData( folder, 'fixB' ,redo, [], {} ); 
%-----------------------------------------------------------------------
%%%  'natgem': get the natural geminals of dof1 and dof2 at every xtimestep
%%%            (xend  = 0) or at the last time (xend = 1).
%%%
%%%             ## --> GetData( folder, 'natgem' ,redo, [dof1, dof2, xtimestep, xend], {} ); 
%-----------------------------------------------------------------------
%%%  'natpop2': get the natural populations of the two-body reduced density matrices of dof1 and dof2 at every xtimestep
%%%            (xend  = 0) or at the last time (xend = 1).
%%%
%%%             ## --> GetData( folder, 'natpop2' ,redo, [dof1, dof2, xtimestep, xend], {} ); 
%-----------------------------------------------------------------------
%%%  'ns_index':get content of ns_index file. 
%%%
%%%             ## --> GetData( folder, 'ns_index' ,redo, [], {} ); 
%-----------------------------------------------------------------------
%%%
%%%%%%%%%%%%%%%%%%%%%
%%% END EXPLANATION OF CASES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%----Is run ready (works only for runs executed on the queue) ?
if length(dir([ folder 'job*.sh'])) < 1
    warning('Run Not finished jet')
    return
end

switch type
    %-------------------  PARAMS ---------------------------------------
    case 'params'   
        if exist([folder 'params.mat'], 'file') ~= 2
            error('No parameter file found')
            return
        end
        data = load([folder 'params.mat']);
    
    %-------------------  OUTPUT ---------------------------------------
    case 'output'   
        if exist([folder '/output.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --output''']);
            [r,s]=system(cmd);
        end
        data = load([folder 'output.mat']);
        
    %-------------------  GPOP ---------------------------------------
    case 'gpop'
        if exist([folder '/gpop.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --gpop''']);
            [r,s]=system(cmd);
        end
        data = load([folder 'gpop.mat']);
        
    %-------------------  NATPOP ---------------------------------------
    case 'natpop'
        if exist([folder '/natpop.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --npop''']);
            [r,s]=system(cmd);
        end
        data = load([folder 'natpop.mat']);
        
        
    %-------------------  NATORBS ---------------------------------------
    case 'natorb'
        if length(numargs) ~= 3
            error('Wrong input for natgem data given')
        end
        dof= numargs(1);
        xtstep= numargs(2);
        xend = numargs(3); % Only last time step ?
        psiadd = '';
        if xend && (exist([folder '/psi_last'], 'file') ~= 2 || redo)
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi -opr hamilt''']);
            [r1,s1]=system(cmd);
            copyfile([ folder 'restart'], [ folder 'psi_last'] )
            psiadd = '_last';
            xtstep = 1;
        end
        if exist([folder '/natorb_' num2str(dof)], 'file') ~= 2        || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi' psiadd  ' -opr hamilt -norb ' num2str(dof) ' -xtstep ' num2str(xtstep) '''']);
            [r1,s1]=system(cmd);
        end
        
        if exist([folder '/natorb_' num2str(dof) '.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --norb -i natorb_' num2str(dof) '''']);
            [r,s]=system(cmd);
        end
        data = load([folder 'natorb_' num2str(dof) '.mat']);
        
        
    %-------------------  PSI ---------------------------------------
    case 'psi'
        if length(strargs) == 1
            psiFileName= strargs{1};
        else
            psiFileName = 'psi';
        end
        if exist([folder '/' psiFileName '.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --psi -i ' psiFileName ' -o ' psiFileName ' ''']);
            [r,s]=system(cmd);
        end
        data = load([folder psiFileName '.mat']);
        
    %-------------------  Expectation VALUE--------------------------------
    case 'expect'
        if length(strargs) ~= 2
            error('Wrong input for expectation value data given')
        end
        operFileName= strargs{1};
        operName= strargs{2};
        if exist([folder '/' operName], 'file') ~= 2 || redo
            copyfile([ operFileName '.py'],folder)
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; python ' operFileName '.py''']);
            [r1,s1]=system(cmd);
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_expect.x -rst restart -opr op_' operName ' -psi psi -save ' operName ' ''']);
            [r1,s1]=system(cmd);
        end
        if exist([folder '/' operName '.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --expect -i ' operName ' -o ' operName ' ''']);
            [r2,s2]=system(cmd);
        end
        data = load([folder operName '.mat']);
        
        
    %-------------------  DMAT ---------------------------------------
    case 'dmat'
        if length(numargs) ~= 2
            error('Wrong input for dmat data given')
        end
        dof1= numargs(1);
        xtstep= numargs(2);
        if exist([folder '/dmat_dof' num2str(dof1) '_grid'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart.ini -psi psi -opr hamilt -dmat -dof ' num2str(dof1)  ' -xtstep ' num2str(xtstep) ' -structured_output''']);
            [r1,s1]=system(cmd);
        end
        if exist([folder '/dmat_dof' num2str(dof1)  '_grid.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --gden -i dmat_dof' num2str(dof1) '_grid''']);
            [r2,s2]=system(cmd);
        end
        data = load([folder 'dmat_dof' num2str(dof1) '_grid.mat']);  
        
       
    %-------------------  DMAT 2 ---------------------------------------
    case 'dmat2'
        if length(numargs) ~= 4
            error('Wrong input for dmat2 data given')
        end
        dof1= numargs(1);
        dof2= numargs(2);
        xtstep= numargs(3);
        xend = numargs(4); % Only last time step ?
        psiadd = '';
        if xend && (exist([folder '/psi_last'], 'file') ~= 2 || redo)
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi -opr hamilt''']);
            [r1,s1]=system(cmd);
            copyfile([ folder 'restart'], [ folder 'psi_last'] )
            psiadd = '_last';
            xtstep = 1;
        end
        if exist([folder '/dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart.ini -psi psi' psiadd  ' -opr hamilt -dmat2 -dof ' num2str(dof1)  ' -dofB ' num2str(dof2)  ' -xtstep ' num2str(xtstep) ' -structured_output''']);
            [r1,s1]=system(cmd);
        end
        if exist([folder '/dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --red2b -i dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid''']);
            [r2,s2]=system(cmd);
        end
        data = load([folder 'dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid.mat']);

        
               
    %-------------------  Fixed Basis analysis ---------------------------------------
    case 'fixB'
        if exist([folder '/restart.ini'], 'file') == 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; cp restart.ini restart_fix ''']);
            [r2,s2]=system(cmd);
        else
            error('restart.ini not found')
        end
        if exist([folder '/fixb'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -fixed_ns -rst_bra restart_fix -rst_ket restart  -save fixb -psi psi ''']);
            [r1,s1]=system(cmd);
        end
        if exist([folder '/fixb.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --fixb ''']);
            [r2,s2]=system(cmd);
        end
        data = load([folder 'fixb.mat']);
        
               
    %-------------------  natural geminals ---------------------------------------
    case 'natgem'
        if length(numargs) ~= 4
            error('Wrong input for natgem data given')
        end
        dof1= numargs(1);
        dof2= numargs(2);
        xtstep= numargs(3);
        xend = numargs(4); % Only last time step ?
        psiadd = '';
        if xend && (exist([folder '/psi_last'], 'file') ~= 2 || redo)
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi -opr hamilt''']);
            [r1,s1]=system(cmd);
            copyfile([ folder 'restart'], [ folder 'psi_last'] )
            psiadd = '_last';
            xtstep = 1;
        end
        if exist([folder '/evec_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid.mat' ], 'file') ~= 2        || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi' psiadd ' -opr hamilt  -dmat2 -diagonalize -onlydiag -dof ' num2str(dof1)  ' -dofB ' num2str(dof2)  ' -xtstep ' num2str(xtstep) ' -structured_output -gridrep''']);
            [r1,s1]=system(cmd);
        end
        if exist([folder '/evec_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --evec_spf -i evec_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid''']);
            [r,s]=system(cmd);
            delete([folder '/evec_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid' ])
        end
        data = load([folder 'evec_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid.mat']);
        
        
        
    %-------------------  natural populations of dmat2 ---------------------------------------
    case 'natpop2'
        if length(numargs) ~= 4
            error('Wrong input for natpop2 data given')
        end
        dof1= numargs(1);
        dof2= numargs(2);
        xtstep= numargs(3);
        xend = numargs(4); % Only last time step ?
        psiadd = '';
        if xend && (exist([folder '/psi_last'], 'file') ~= 2 || redo)
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi -opr hamilt''']);
            [r1,s1]=system(cmd);
            copyfile([ folder 'restart'], [ folder 'psi_last'] )
            psiadd = '_last';
            xtstep = 1;
        end
        if exist([folder '/eval_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '_grid' ], 'file') ~= 2        || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; qdtk_analysis.x -rst restart -psi psi' psiadd ' -opr hamilt  -dmat2 -diagonalize -onlyeigval -dof ' num2str(dof1)  ' -dofB ' num2str(dof2)  ' -xtstep ' num2str(xtstep) ' -structured_output -gridrep''']);
            [r1,s1]=system(cmd);
        end
        if exist([folder '/eval_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '.mat'], 'file') ~= 2 || redo
            cmd=sprintf(['/bin/bash --login -c ''cd ' folder '; OutputSTD.py --eval -i eval_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '''']);
            [r,s]=system(cmd);
        end
        data = load([folder 'eval_dmat2_dof' num2str(dof1) '_dof' num2str(dof2) '.mat' ]);
        
        
    %-------------------  ns_index file ---------------------------------------
    case 'ns_index'     
        formatSpec = '%s%[^\n\r]';
        fileID = fopen([folder 'ns_index'],'r');
        g = textscan(fileID, '%s',  'Delimiter', '\n');
        lines = g{1};
        ns={};
        speccount = 0;
        for jj = 1:length(lines)
            if ~isempty(strfind(lines{jj},'-')); continue;end
            if strfind(lines{jj},'$') == 1
                speccount = speccount +1;
                if speccount > 1
                    ns_all{speccount-1} = ns;
                    ns={};
                end
                continue
            end
            tmp = textscan(lines{jj},formatSpec,  'Delimiter', '=', 'WhiteSpace', '', 'ReturnOnError', false);
            ns{end+1} = [ '$' strrep(strrep(strrep(cell2mat(tmp{2}), ' | ', '|'),' >','>'),' ',',') '$'];
        end
        ns_all{speccount} = ns;
        
        %dataArray = textscan(fileID, formatSpec,  'Delimiter', '', 'WhiteSpace', '', 'HeaderLines', 2, 'ReturnOnError', false);
        %fclose(fileID);
        %fixedNumberState = dataArray{:, 1};
        %fixedNumberState = fixedNumberState(1:end-1);
        data = ns_all;
        
    %-------------------  NO option found ---------------------------------------       
    otherwise
        disp('Type NOT supported yet');
end
   


end

