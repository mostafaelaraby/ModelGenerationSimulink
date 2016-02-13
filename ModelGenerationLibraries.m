%@author		Mostafa ElAraby
%@link	http://www.linkedin.com/in/mostafaelaraby
%@copyright		2016 Mostafa ElAraby
%Model Generation Libraries APIs
%13/2/2016
%compatible with Matlab 2008


classdef ModelGenerationLibraries
    properties (GetAccess='public', SetAccess='private')
        modelName;
    end
    methods (Access = public)
        %% class constructor
        %default constructor
        %@param modelName
        %@param newModel flag 0 to read already existing model
        %flag 1 to create a new model
        function  [modelObject] = ModelGenerationLibraries(modelName,newModel)
            if nargin ==0
                modelObject.modelName = '';
                return
            end
            modelObject.modelName = modelName;
            
            if newModel
                try
                    modelObject.createNewModel();
                catch error
                    %error caused by invalid model name exception
                    modelObject.handleError(error);
                end
            else
                %check if model exist by loading it
                try
                    modelObject.loadLibrary(modelObject.modelName);
                catch error
                    modelObject.handleError(error);
                end
            end
        end
        %% model initialization and saving
        %@param current Class object
        function  createNewModel(modelObject)
            if (exist([modelObject.modelName '.mdl'], 'file'))
                if (bdIsLoaded(modelObject.modelName))
                    Simulink.BlockDiagram.deleteContents(modelObject.modelName);
                else
                    load_system(modelObject.modelName);
                    Simulink.BlockDiagram.deleteContents(modelObject.modelName);
                end
            else
                if (bdIsLoaded(modelObject.modelName))
                    Simulink.BlockDiagram.deleteContents(modelObject.modelName);
                else
                    new_system(modelObject.modelName);
                end
            end
        end
        %@param current Class object
        function saveModel(modelObject,outputDirectory)
            try
                save_system(modelObject.modelName,[outputDirectory '\' modelObject.modelName '.mdl'],'OverWriteIfChangedOnDisk',true);
                modelObject.close_system();
            catch error
                modelObject.handleError(error);
            end
        end
		function close_system(modelObject)
		try
			close_system(modelObject.modelName);
		catch error
			modelObject.handleError(error);
		end
		end
        %% Blocks drawing
        %@param modelObject
        %@param inputName inputName of the inport the from block is coming from
        %@param  subsystemPath is the path of the subsystem relative to
        %the modelName for example modelname/subsystemName/subsystem22
        %subsystemPath of subsystemName is subsystemName
        %subsystemPath of subsystemName subsystem22 is subsystemName/subsystem22
        function[fromName]= addFromBlock(modelObject,subsystemPath,inputName,pos)
			
			if ~strcmp(subsystemPath,'')
				subsystemPath = char(strcat('/',subsystemPath));
			end
                try
                    fromName =  char(strcat(inputName,'_from'));
                    fromHandle = add_block('simulink/Signal Routing/From',char(strcat(modelObject.modelName,subsystemPath,'/', inputName,'_from')),'Position',pos);
                catch
                    FromCount = 1;
                    while true
                        try
                            fromName =  char(strcat(inputName,'_from',int2str(FromCount)));
                            fromHandle = add_block('simulink/Signal Routing/From',char(strcat(modelObject.modelName,subsystemPath,'/', inputName,'_from',num2str(FromCount))),'Position',pos);
                            break;
                        catch
                            FromCount = FromCount+1;
                        end
                    end
                end
                set_param(fromHandle,'GotoTag',char(inputName));
        end
		
		
		function[gotoName]= addGoTOBlock(modelObject,subsystemPath,inputName,pos)
                try
                    gotoName =  char(strcat(inputName,'_goto'));
                    gotoHandle = add_block('simulink/Signal Routing/Goto',char(strcat(modelObject.modelName,'/',subsystemPath,'/', inputName,'_goto')),'Position',pos);
                catch error
				modelObject.handleError(error);
                end
                set_param(gotoHandle,'GotoTag',char(inputName));
        end
        
        %@param modelObject
        %@param libraryPath path of the library
        %@param subsystemPath path of the subsystem
        %@param subsystemName name of the block to be added
        %@param pos is the position fo the generated block
        %@eturn blockHandle of the added block
		function  [blockHandle] = addLibraryBlock(modelObject,libraryPath,subsystemPath,subsystemName,pos)
			try
				if strcmp(subsystemPath,'')
					blockHandle = add_block(libraryPath,strcat(modelObject.modelName,'/',subsystemName),'Position',pos);
				else
					blockHandle = add_block(libraryPath,strcat(modelObject.modelName,'/',subsystemPath,'/',subsystemName),'Position',pos);
				end
			catch error
					modelObject.handleError(error);
			end
		end
		%relative pathes
        %@param relativeSubsystemPath path for 
        %the parent subsystem where the lines should be added
        %@param sourceSubsystemName is the name of the source subsystem
        %@param destSubsystemName is the name of the destination subsystem 
        %@param sourcePortNumber is the port number of the source subsytem (the pin number that you wish to connect)
        %@param destportNumber  is the port number of the destination subsytem (the pin number that you wish to connect)
		function addLine(modelObject,relativeSubsystemPath,sourceSubsystemName,destSubsystemName,sourcePortNumber,destportNumber)
			try
				if isnumeric(sourcePortNumber)
					sourcePortNumber = num2str(sourcePortNumber);
				end
				if isnumeric(destportNumber)
					destportNumber = num2str(destportNumber);
				end
				if  strcmp(relativeSubsystemPath,'')
						add_line([modelObject.modelName],char(strcat(sourceSubsystemName,'/',sourcePortNumber)),char(strcat(destSubsystemName,'/',destportNumber)),'autorouting','on');
				else
					add_line([modelObject.modelName '/' relativeSubsystemPath],char(strcat(sourceSubsystemName,'/',sourcePortNumber)),char(strcat(destSubsystemName,'/',destportNumber)),'autorouting','on');
				end
			catch error
				modelObject.handleError(error);
			end
		end
        %@param modelObjetc of the current class
        %@param type of operator Logical or Relational
        %@param blockPath relative  path of operator block relative to
        %model same as subsystemPath
        %@param pos of the block
        %@param operator is the operator type for example AND OR ... etc
        %or
        function addOperatorBlock(modelObject,type,blockPath,pos,operator)%relational or logical
            try
                relationalBlock = add_block(['simulink/Commonly Used Blocks/' type ' Operator'],char(strcat(modelObject.modelName,'/',blockPath)),'Position',pos);
                set_param(relationalBlock,'operator',operator);
            catch error
                handleError(error);
            end
        end
        %@param constantPath relative path of the constant block
        %@param pos
        %@param  value  which is the value of the constant block
        function addConstantBlock(modelObject,constantPath,pos,value)
            constantBlock = add_block('simulink/Commonly Used Blocks/Constant',char(strcat(modelObject.modelName,'/',constantPath)),'Position',pos);
            try
                set_param(constantBlock,'Value',value);
            catch error
                set_param(constantBlock,'Value',['error_' value]);
                modelObject.handleError(error);
            end
        end
		function arr = split(modelObject,string, delimiter)
            try
                arr = strread(string,'%s','delimiter',delimiter);
            catch error
                modelObject.handleError(error);
            end
		end
        %@param  modelObject object holding modelname
        %@param subsystemName relative path of subsystem where the merge should be added
        %@param  outputblockName is the name of the ouput port
        %@param fromSubsystem is the name of the subsystem which is
        %producing the output
        %@param inputEnabledSubsystemIndex the port Number of the outport
        function[done] =  createMergeblock(modelObject,subsystemName,outputblockName,fromSubsystem,inputEnabledSubsystemIndex)
            outputblockPath = strcat(modelObject.modelName,'/',subsystemName,'/',outputblockName);
            done = 1;
            try
                PortHandles = get_param(char(outputblockPath),'PortHandles');
                PortHandles = PortHandles.Inport;
                line = get_param(PortHandles,'line');
                SrcBlock = get_param(line,'SrcPortHandle');
            catch error
                done = 0;
                modelObject.handleError(error);
                return;
            end
            try
                pos = get_param(char(outputblockPath),'Position');
                posNew = [pos(1)+100 pos(2) pos(1)+100+30 pos(2)+30];
                set_param(char(outputblockPath),'Position',posNew);
                pos = [pos(1)-100 pos(2) pos(1)-100+30 pos(2)+30];
                add_block('simulink/Signal Routing/Merge',char(strcat(outputblockPath,'_merge')),'Position',pos);
                mergeCount = 2;
            catch
                mergeCount = str2double(get_param(char(strcat(outputblockPath,'_merge')),'Inputs'));
                mergeCount = mergeCount+1;
            end
            try
                if mergeCount>2
                    pos = get_param(char(strcat(outputblockPath,'_merge')),'Position');
                    pos = [pos(1)-15 pos(2)-15 pos(1)+15 pos(2)+15];
                    set_param(char(strcat(outputblockPath,'_merge')),'Inputs',int2str(mergeCount));
                    set_param(char(strcat(outputblockPath,'_merge')),'Position',pos);
                end
                
                
                SrcPortnumber = get_param(SrcBlock,'PortNumber');
                SrcBlock = get_param(line,'SrcBlockHandle');
                delete(line);
                SrcblockName = modelObject.split(getfullname(SrcBlock), '/');
                SrcblockName(strcmp('',SrcblockName)) = [];
                SrcblockName = SrcblockName{end};
                if mergeCount>2
                    add_line(subsystemName,char(strcat(fromSubsystem,'/',int2str(inputEnabledSubsystemIndex))),char(strcat(outputblockName,'_merge','/',int2str(mergeCount))),'autorouting','on');
                    add_line(subsystemName,char(strcat(outputblockName,'_merge','/1')),char(strcat(outputblockName,'/1')),'autorouting','on');
                    
                else
                    add_line(subsystemName,char(strcat(fromSubsystem,'/',int2str(inputEnabledSubsystemIndex))),char(strcat(outputblockName,'_merge','/',int2str(mergeCount))),'autorouting','on');
                    add_line(subsystemName,char(strcat(SrcblockName,'/',int2str(SrcPortnumber))),char(strcat(outputblockName,'_merge','/',int2str(mergeCount-1))),'autorouting','on');
                    add_line(subsystemName,char(strcat(outputblockName,'_merge','/1')),char(strcat(outputblockName,'/1')),'autorouting','on');
                    
                end
            catch error
                handle(error);
            end
        end
        
        %% subsystem creation
        %@param modelObject class
        %@param subSystemRelativePath relative path to the modelname for example
        %if its current path is modelName/Main/subsystemName
        %then relative path is Main/subsystemName
        %@param TriggerName   is the name of the trigger event which is same as the subsystem name in most cases
        %@param inputNames is a cell array of input names
        %@param outputNames is a cell array  of output names
        %@param  X is the starting x coordinate  which is the relative position from the left to the current subsystem
        %@param lastY2 is the last y coordinate   of the previous subsystem  for offset purposes
        %@param isTrigger boolean 0 for normal subsystems and 1 for trigger subsystems
        %@param addFroms boolean  0 for from blocks and 1 to add normal inputs
        %@param isNotInternal means that the outputs of this subsystem will be internally consumed by another subsystem
        %@param internalInputs  means that inputs to that subsystem are coming from another subsystem
        %@param fromsubSystemName is the name of the subsystem that will produce outputs in csae of internal inputs of current subsystem
        %@return lastY2 the last position of the current subsystem for looping purposes and putting more than 1 subsystem above each other
        %@return disconnectedPortsInput the index of inports that the function was unable to resolve its source
        %@return subsystemPos position of the newly created subsystem
        function [lastY2,disconnectedPortsInput,subsystemPos] = createSubsystem(modelObject,subSystemRelativePath,TriggerName,inputNames,outputNames,X,lastY2,isTrigger,addFroms,isNotInternal,internalInputs,fromsubSystemName)
            try
                parentSubsystemName = modelObject.split(subSystemRelativePath,'/');
                currentSubsystemName = parentSubsystemName{end};
                parentSubsystemName = parentSubsystemName{1:end};
                Y1 = lastY2+87;
                Y2 = Y1+max(numel(inputNames),numel(outputNames))*30;
                disconnectedPortsInput= cell(0,1);
                if Y1==Y2
                    Y2 = Y1+150;
                end
                height = Y2-Y1;
                numberOfInputPorts = numel(inputNames);
                taw = height/numberOfInputPorts;
                if numberOfInputPorts>1
                    unitX = int16(taw)-1;
                    newTaw = height/(numberOfInputPorts-1);
                    unitY = (newTaw-unitX)/2;
                else
                    unitX = int16(taw)-1;
                    newTaw = height/(numberOfInputPorts);
                    unitY = (newTaw-unitX)/2;
                end
                
                subsystemPos = [X Y1 X+400 Y2];
                add_block('built-in/Subsystem',[modelObject.modelName '/' subSystemRelativePath],'Position',subsystemPos);
                
                
                if isTrigger
                    triggerBlock = add_block('built-in/TriggerPort',[modelObject.modelName '/' subSystemRelativePath '/' TriggerName],'Position',[360 50 390 70]);
                    set_param(triggerBlock,'TriggerType','function')
                end
                innerY2 = 100;
                for i=1:numel(inputNames)
                    inputPath = strcat(modelObject.modelName, '/' ,subSystemRelativePath ,'/', inputNames{i});
                    pos = [100 innerY2+30 130 innerY2+50];
                    add_block('built-in/Inport',inputPath,'Position',pos);
                    innerY2 = innerY2+50;
                    
                    tag = char(strcat(inputNames{i}));
                    
                    if addFroms
                        pos = [X-300 Y1+(32*(i)) X-270+(8*numel(tag)) Y1+15+(32*(i))];
                        [fromName]= modelObject.addFromBlock(parentSubsystemName,inputNames{i},pos);
                        modelObject.addLine(parentSubsystemName,fromName,currentSubsystemName,1,i);
                    else
                        try
                            if internalInputs
                                modelObject.addLine(parentSubsystemName,fromsubSystemName,currentSubsystemName,1,i);
                            else
                                
                                %adjust inport new position
                                %pos = [pos(1) pos(2) pos(1)+20 pos(2)+20];
                                inputPos =  get_param(char(strcat(modelObject.modelName,'/',inputNames{i})),'Position');
                                width = inputPos(3)-inputPos(1);
                                if i==1
                                     pos = [X-300 Y1+unitY+(15/2) X-300+width Y1+unitY+(15/2)+15];
                                else
                                   pos = [X-300 Y1+unitY+(unitX*(i-1))+(15/2) X-300+width Y1+unitY+(unitX*(i-1))+(15/2)+15];
                                end
                                pos = double(pos);
                                set_param(char(strcat(modelObject.modelName,'/',inputNames{i})),'Position',pos);
                                modelObject.addLine(inputNames{i},subSystemRelativePath,1,i);
                            end
                        catch
                            disconnectedPortsInput{end+1} = int2str(i);
                        end
                    end
                end
                innerY2 = 100;
                for i=1:numel(outputNames)
                    outputPath = strcat(modelObject.modelName, '/' ,subSystemRelativePath ,'/', outputNames{i});
                    pos = [500 innerY2+30 530 innerY2+50];
                    modelObject.addLibraryBlock('built-in/Outport',subSystemRelativePath,outputNames{i},pos);
                    innerY2 = innerY2+50;
                    if isNotInternal
                        pos = [X+600 Y1+(40*(i-1)) X+600+20 Y1+20+(40*(i-1))];
                        try
                            %outputPath = strcat(modelObject.modelName,'/',outputNames{i});
                            
                            %outputName = strcat(outputNames{i});
                            modelObject.addLibraryBlock('built-in/Outport','',outputNames{i},pos);
                            modelObject.addLine('',subSystemRelativePath,outputName,i,1);
                        catch
                            % add a  merge block
                            type = get_param(outputPath,'blockType');
                            if strcmpi(type,'outport')
                                %Main is the parent of the current path
                                done =  modelObject.createMergeblock(parentSubsystemName,outputNames{i},subSystemRelativePath,i);
                                if ~done
                                    set_param(outputPath,'Position',pos);
                                    modelObject.addLine('',subSystemRelativePath,outputNames{i},i,1);
                                end
                            else
                                display(sprintf('Error : You are trying to add p_varname %s as outport in RX_frame subsystem %s while it exists in the same  Main subsystem as inport in another TX_frame',outputNames{i},subSystemRelativePath));
                            end
                        end
                    end
                end
                set_param([modelObject.modelName '/' subSystemRelativePath],'Position',subsystemPos);
               
                lastY2 = Y2;
            catch error
                modelObject.handleError(error);
            end
        end

        %% function to restart routing of lines to fix triangular lines
        %% generated due to alignement of ports or hanging of position of
        %% a block
        function restartRouting(modelObject)
            lines = modelObject.sortLinesbyPortNumber();
            for i=1:numel(lines)
                try
                    srcBlockHandle = get_param(lines(i),'SrcBlockHandle');
                    srcPortHandle = get_param(lines(i),'SrcPortHandle');
                    dstPortHandle = get_param(lines(i),'DstPortHandle');
                    srcPortNumber = get_param(srcPortHandle,'PortNumber');
                    dstPortNumber = get_param(dstPortHandle,'PortNumber');
                catch
                    continue;
                end
                dstBlockHandle = get_param(lines(i),'DstBlockHandle');
                if iscell(dstPortNumber)
                    dstPortNumber = cell2mat(dstPortNumber);
                end
                delete_line(lines(i));
                for j=1:numel(dstPortNumber)
                    if ~isempty(srcBlockHandle) && ~isempty(dstBlockHandle(j))
                        srcBlockName = modelObject.split(getfullname(srcBlockHandle),'/');
                        dstBlockName = modelObject.split(getfullname(dstBlockHandle(j)),'/');
                        currentSubsystem = strjoin(srcBlockName(1:end-1),'/');
                        try
                            blockDescription = get_param(srcBlockName{end-1},'MaskDescription');%to avoid error caused by Matlab Embedded block
                            if strcmpi(blockDescription,'Embedded MATLAB block')
                                continue;
                            end
                        catch
                            try
                                blockDescription = get_param(dstBlockName{end-1},'MaskDescription');%to avoid error caused by Matlab Embedded block
                                if strcmpi(blockDescription,'Embedded MATLAB block')
                                    continue;
                                end
                            catch
                            end
                        end
                        try
                            add_line(currentSubsystem,char(strcat(srcBlockName(end),'/',int2str(srcPortNumber))),char(strcat(dstBlockName(end),'/',int2str(dstPortNumber(j)))),'autorouting','on');
                        catch
                            %trigger
                            try
                                add_line(currentSubsystem,char(strcat(srcBlockName(end),'/',int2str(srcPortNumber))),char(strcat(dstBlockName(end),'/Trigger')),'autorouting','on');
                            catch
                                %enable
                                add_line(currentSubsystem,char(strcat(srcBlockName(end),'/',int2str(srcPortNumber))),char(strcat(dstBlockName(end),'/Enable')),'autorouting','on');
                            end
                        end
                    end
                    
                end
                
            end
        end
        
        %% returns all lines in a model sorted by its depth in model
        function simulinkObjectsOut = sortLinesbyPortNumber(modelObject)
            %linear sort
            simulinkObjects = find_system(modelObject.modelName,'FindAll', 'on','lookundermasks','all', 'Type', 'line');
            numberOfObjects = numel(simulinkObjects);
            simulinkObjectsOut = cell(numberOfObjects,1);
            tempObjects = cell(numberOfObjects,1);
            tempDepth = cell(numberOfObjects,1);
            for i=1:numberOfObjects
                tempObjects(i) = {simulinkObjects(i)};
                portNumber = get_param(get_param(simulinkObjects(i),'DstPortHandle'),'PortNumber');
                if numel(portNumber)>1
                    portNumber = portNumber{1};
                end
                tempDepth(i) ={ portNumber};%the depth of the current line
            end
            [~, Index_Depth] = sort(cell2mat(tempDepth),'descend');
            simulinkObjectsOut(:,1) = tempObjects(Index_Depth);
            simulinkObjectsOut = cell2mat(simulinkObjectsOut);
        end
        %% fix naming errors of a model 
        function fixModelSubsystemNames(modelObject)
            SubSystemsNames = find_system(modelObject.modelName, 'LookUnderMasks', 'none', 'BlockType', 'SubSystem', 'MaskType', ''); % subsytems names
            sfSubs    = find_system(modelObject.modelName, 'LookUnderMasks', 'none', 'BlockType', 'SubSystem', 'MaskType', 'Stateflow');
            fullnames = [SubSystemsNames;sfSubs];
            len=length(fullnames);
            names = cell(len);
            for i=1:len
                names{i} = strrep(fullnames{i}, '.', '/');
                sep      = findstr(names{i}, '/');
                names{i} = names{i}(sep(end)+1:end);
            end
            
            if(isempty(names))
                return;
            end
            
            unic = unique(names);
            if(len~=length(unic))
                len = length(unic);
                for i=1:len
                    f=find(strcmp(unic{i}, names));
                    nb=length(f);
                    if(nb>1)
                        for j=2:nb
                            set_param(fullnames{f(j)},'name',[names{f(j)} num2str(j)]);
                        end
                    end
                end
            end
        end

        

        %% library loading
        function loadLibrary(modelObject,libraryName)
            try
                open_system(libraryName,'loadonly');
            catch err
                disp(['Error loading library ' liraryName]);
                modelObject.handleError(err);
            end
        end
        
        %% error handling
        function  handleError(modelObject,error)
			disp(getReport(error));
			disp('Code put in debugging  mode to check for errors');
			keyboard;
		end
    end
end