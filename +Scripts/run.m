function [ runAna ] = run( folder )
%RUN Return the run specific parameters 
%   Analyses the folder name and returns the iteration variable and the
%   system used.
%--------------------------------------------------------------------------
%------  Analysis tool for MCTDHB calculations 
%------  RUN ANALYSER
%------  J. Schurer 27.01.2014
%------ @in folder: name of the folder to analyse (runXXX_XXXX) 
%--------------------------------------------------------------------------

switch folder(4)
    case '1' 
        system = 'LLP';
    case '2' 
        system = 'static ionic';
    case '3' 
        system = 'relativeWithCOM';
    case '4' 
        system = 'relative';
    case '6'
        system = 'dynamic ionic';
    case '8'
        system = 'relative bosons';
    otherwise
        system = 'NOT Identified';
end

switch folder(5)
    case '1' 
        method = 'relax';
    case '2' 
        method = 'improved relax';
    case '3' 
        method = 'propagate';
    otherwise
        method = 'NOT Identified';
end

switch folder(6)
    case '0' 
        iter='cont';
    case '1' 
        iter='N';
    case '2' 
        iter='g';
    case '3' 
        iter='lparIon';
    case '4' 
        iter='omega';
    case '5' 
        iter='lpar';
    case '6' 
        iter='m';
    case '7' 
        iter='n';
    case '8' 
        iter='MA';
    case '9' 
        iter='mI';
    otherwise
        iter = 'NOT Identified';
end

runNum = folder(8:end);

runAna{1} = system;
runAna{2} = method;
runAna{3} = iter;
runAna{4} = runNum;

end

