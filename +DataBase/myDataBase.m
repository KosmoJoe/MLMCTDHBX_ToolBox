%--------------------------------------------------------------------------
%------  Load or create SQL database for MCTDHB calculations 
%------  Tool to work with SQL database
%------  J. Schurer 19.02.2018
%--------------------------------------------------------------------------

function [ data ] = myDataBase( database, operation , strargs, numargs)
%myDataBase: Function which handels loading/storing informations on runs
%            in a sqlite database. 
% INPUTS:
%  @in database: file name of the database to use
%  @in operation: operation you want to execute on the database (see below)
%  @in numargs: list of nummeric arguments whose meaning is specified for each operation
%  @in strargs: list of string arguments whose meaning is specified for each operation
%
%  @out data: container of the data specified by type 

if ~exist('database','var'), error('No Database given'); end
if ~exist('operation','var'), error('No Operation type given'); end
if ~exist('help','var'), help='WTF'; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EXPLANATION OF CASES
%%%%%%%%%%%%%%%%%%%%%
%%%
%%%  operation = 
%%%
%-----------------------------------------------------------------------
%%%  'setNew':      set-up a completly new (and empty) database with name database
%%%
%%%                 ## --> myDataBase( database, 'setNew')
%-----------------------------------------------------------------------
%%%  'fill':        fill data into a database. Use all runs which are in dataFolder.
%%%
%%%                 ## --> myDataBase( database, 'fill', {dataFolder}, [])
%-----------------------------------------------------------------------
%%%  'loadSingle':  load the parameters of a single run in folder
%%%
%%%                 ## --> myDataBase( database, 'loadSingle', {folder}, [])
%-----------------------------------------------------------------------
%%%  'getFolder':   get the folders which contain data which fits the
%%%  condition specified by strargs. Here strargs{1} = condition to
%%%  parameters and strargs{2} = conditions to run type
%%%  (if condition{i} == '' no restriction is set)
%%%
%%%                 ## --> myDataBase( database, 'getFolder', strargs, [])
%%%                 ### e.g.: strargs = {'g=1 AND N=10','system=''LLP'' AND method=''relax'''};
%%%                 ### e.g.: strargs = {'omega IN (20,40,60,80)','RunNumber=''run634_N1_local_0.5'''};
%-----------------------------------------------------------------------
%%%  'add':         add a list of folders to the database
%%%
%%%                 ## --> myDataBase( database, 'add', folders, [])
%-----------------------------------------------------------------------
%%%  'addRun':      add a full run to the database in folder
%%%
%%%                 ## --> myDataBase( database, 'addRun', {folder}, [])
%-----------------------------------------------------------------------
%%%
%%%%%%%%%%%%%%%%%%%%%
%%% END EXPLANATION OF CASES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



dataBaseFolder = '+DataBase/';

%----Subfolder in run ready ?
if exist([dataBaseFolder, database, '.db'], 'file') ~= 2
    if operation ~= 'setNew'
        warning('Database does not exist yet ! Please use setNew first')
        return
    end
end

dbfile = fullfile(dataBaseFolder,[database, '.db']);

switch operation
    %-------------------  Set up a complete data base ---------------------------------------
    case 'setNew'
        conn = sqlite(dbfile,'create');
        defineDataBase(conn);
        close(conn);
    %-------------------  Fill a complete data base ---------------------------------------
    case 'fill'
        conn = sqlite(dbfile,'connect');
        dataFolder = strargs{1};
        d = dir(dataFolder);
        isub = [d(:).isdir]; %# returns logical vector
        subfolder = {d(isub).name}';
        subfolder(ismember(subfolder,{'.','..'})) = [];

        %----Resort folder
        s=cellfun(@size,subfolder,'uniform',false);
        [~, is]=sortrows(cat(1,s{:}),[1 2]);
        subfolders=subfolder(is);
        
        for jj=1:length(subfolders)
            disp(jj)
            addRun(conn,[dataFolder subfolders{jj} '/'])
        end
        close(conn);
        
    %-------------------  Load single entry from database  ---------------------------------------
    case 'loadSingle'
        conn = sqlite(dbfile,'connect');
        folder = strargs{1};
        data = loadSingleFromFolder(conn, folder);
        close(conn);
        
    %-------------------  Load a Set of entries which fulfill contrain ---------------------------------------
    case 'loadSet'
        
    %-------------------  Load a Set of entries which fulfill contrain ---------------------------------------
    case 'getFolder'
        conn = sqlite(dbfile,'connect');
        data = getFoldersFromCondition(conn, strargs);
        close(conn);
    %-------------------  Add (a) new entry(s) to the data base ---------------------------------------
    case 'add'
        conn = sqlite(dbfile,'connect');
        for kk = 1:length(strargs)
            folder = strargs{kk};
            add(conn, folder)
        end
        close(conn);
        
    %-------------------  Add (a) new RUN(s) to the data base ---------------------------------------
    case 'addRun'
        conn = sqlite(dbfile,'connect');
        folder = strargs{1};
        addRun(conn, folder)
        close(conn);
        
    %-------------------  Change an entry in the Database ---------------------------------------
    case 'changeSingle'    
       
    %-------------------  NO option found ---------------------------------------       
    otherwise
        disp('Type NOT supported yet');
end


    %%% Function which defines the form of the dataSet
    function defineDataBase(connection)
        exec(connection, 'PRAGMA case_sensitive_like=true;')
        createRunTypeTable = ['CREATE TABLE runType ' ...
            '(id INTEGER PRIMARY KEY AUTOINCREMENT,' ...
            'Folder TEXT,' ...
            'System TEXT,' ...
            'Method TEXT, ' ...
            'IterationParameter TEXT,' ...
            'RunNumber TEXT, ' ...
            'Comment TEXT)'];
        exec(connection,createRunTypeTable)

        createParameterTable = ['CREATE TABLE parameter ' ...
            '(id INTEGER PRIMARY KEY AUTOINCREMENT,' ...
            'mAOmI   NUMERIC,' ...
            'g       NUMERIC,' ...
            'v0      NUMERIC,' ...
            'omega   NUMERIC,' ...
            'gamma   NUMERIC,' ...
            'lpar    NUMERIC,' ...
            'lparI   NUMERIC,' ...
            'm_A     NUMERIC,' ...
            'N       NUMERIC,' ...
            'n_A     NUMERIC,' ...
            'tfinal  NUMERIC,' ...
            'dt      NUMERIC,' ...
            'm_I     NUMERIC,' ...
            'NI      NUMERIC,' ...
            'MA      NUMERIC,' ...
            'MI      NUMERIC,' ...
            'n_I     NUMERIC )'];
        exec(connection,createParameterTable)
    end

    % Check if a folder is already in the data base
    % A folder exists only once so it should not be twice in the database
    function exists = testExist(connection, folder)
        sqlcommand = ['SELECT EXISTS(SELECT 1 FROM runType WHERE folder = ''' folder ''');'];
        cursor = fetch(connection,sqlcommand);
        exists = cursor{1};
    end


    %%% Add a complete RUN to an existing Database
    function addRun(connection, folderMain)
        
        %Get comment
        %----Read In of parameters
        if exist([folderMain 'input.txt' ], 'file') == 2 
            fid = fopen([folderMain 'input.txt' ]);
            line = fgetl(fid); %line = textread([folderMain 'input.txt' ]) 
            comment = line(strfind( line,'-n ''')+4:end-4);
        else
            comment= [];
        end
        
        %Make Path absolute
        currFolder = cd(folderMain);
        folderMain = [pwd '/'];
        cd(currFolder)

        d = dir(folderMain);
        isub = [d(:).isdir]; %# returns logical vector
        subfolder = {d(isub).name}';
        subfolder(ismember(subfolder,{'.','..'})) = [];

        %----Resort folder
        s=cellfun(@size,subfolder,'uniform',false);
        [~, is]=sortrows(cat(1,s{:}),[1 2]);
        subfolder=subfolder(is);
        
        for j=1:length(subfolder)
    
            d = dir(strcat(folderMain, subfolder{j}, '/'));
            isub = [d(:).isdir]; %# returns logical vector
            subsubfolder = {d(isub).name}';
            subsubfolder(ismember(subsubfolder,{'.','..'})) = [];

            for jj = 1:length(subsubfolder)

                folder = strcat( folderMain, subfolder(j),'/', subsubfolder(jj) , '/');
                folder = folder{1};
                
                %----Subfolder in run ready ?
                if length(dir([ folder 'job*.sh'])) < 1
                   break
                end
                
                add(connection, folder, comment);

            end
        end
    end


    %%% Add a new entry to an existing Database
    function add(connection, folder, comment)
        
         if ~exist('comment','var') || isempty(comment)
             % comment does not exists so default it
              comment = 'NA';
         end
        
        %Make Path absolute
        currFolder = cd(folder);
        folder = [pwd '/'];
        cd(currFolder)
        
        %Check if exists
        if testExist(connection,folder)
            warning('You tried to add a folder which is already in the database. Folder is skipped .....')
            return
        end
        
        runAna = Scripts.run(folder(strfind(folder,'run'):end));
        pars = load([folder 'params.mat']);
        
        tablename{1} = 'runType';
        tablename{2} = 'parameter';
        colname{1} = { '"System"', 'Method', 'IterationParameter', 'Folder', 'RunNumber', 'Comment' };
        
        parNames = fieldnames(pars)';
        parNames{strcmp(parNames, 'nI')} = 'n_I';
        parNames{strcmp(parNames, 'm')}  = 'm_A';
        parNames{strcmp(parNames, 'n')}  = 'n_A';
        parNames{strcmp(parNames, 'mI')} = 'm_I';    
        colname{2} = parNames;
        
        runNum = folder(strfind(folder,'run'):end);
        runNum = runNum(1:regexp(runNum,'/', 'once')-1);
        tableData{1} = [runAna(1:3), folder, runNum, comment];
        tableData{2} = struct2cell(pars)';
        
        insert(connection, tablename{1}, colname{1}, tableData{1})
        insert(connection, tablename{2}, colname{2}, tableData{2})
    end

    function data = loadSingleFromFolder(connection, folder)
        
        %Make Path absolute
        currFolder = cd(folder);
        folder = [pwd '/'];
        cd(currFolder)
        
        sqlcommand = ['SELECT * FROM runType WHERE folder=''' folder ''';'];
        cursor = fetch(connection,sqlcommand);
        if isempty(cursor)
            warning('Data is not contained in DataBase')
            return
        end
        
        sqlcommand = ['SELECT * FROM parameter WHERE id=' cursor{1} ';'];
        cursor2 = fetch(connection,sqlcommand);
        data = [cursor cursor2];
    end

    function out = getFoldersFromCondition(connection, conditions)
        
        if ~strcmp(conditions{1}, '')
            sqlcommand = ['SELECT id FROM parameter WHERE ' conditions{1} ';'];
        else
            sqlcommand = ['SELECT id FROM parameter;'];
        end
        cursor = fetch(connection,sqlcommand);
        if isempty(cursor)
           warning('No Data found under given condition')
           return
        end
        
        ids = sprintf('%u,', cell2mat(cursor));
        ids = ids(1:end-1);% strip final comma
        if ~strcmp(conditions{2}, '')
            sqlcommand = ['SELECT folder, id FROM runType WHERE id IN (' ids ') AND ' conditions{2} ';'];
        else
            sqlcommand = ['SELECT folder, id FROM runType WHERE id IN (' ids ');'];
        end
        out = fetch(connection,sqlcommand);
        %folders = out(:,1)
        %idx = out(:,2)
    end

end