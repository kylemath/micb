% Motion-Induced Change Blindness, v.1.2
% Developed by Richard Yao
%
% The code below, paired with the functions micb1_blind and micb1_control,
% display an array of gabor patches that the subject must track vertically
% then horizontally.  The sudden change in direction introduces a motion
% transient that effectively blocks the change.
%
% The current code only has the array move downwards then to the right.
% The change can either occur at the moment of directional change or
% halfway along its horizontal movement path.
%
% This version of the code circumvents a problem on older computers with the
% CreateProceduralGabor function and simply uses an image of a Gabor.
%
% This particular version adds easy manipulation of the number of gabors,
% as well as cleaning up a lot of messy code.

%% Opening stuff

clear all

% warning off

Screen('Preference', 'SkipSyncTests', 1)

clc;

eyetrack = 0 %input('EXPERIMENTER: enable eyetracking (1 = yes, 0 = no)? ');

clc;

% subject = input('Subject Number: ');
% age = input('Age: ');
% sex = input('Sex (M/F): ','s');

seed = ceil(sum(clock)*1000);
rand('twister',seed);

%% Basic parameters

bgcolor = [128 128 128];

% [w rect] = Screen('OpenWindow',0,bgcolor,[0 0 1300 800]);
[w rect] = Screen('OpenWindow',0,bgcolor);
xc = rect(3)./2;
yc = rect(4)./2;

xBorder = round(rect(3)./6);
yBorder = round(rect(4)./6);

textSize = round(rect(4)*.02);
Screen('TextSize',w,textSize);

wrapat = 50;

directionNames = {'Right' 'Left'};

% fixation parameters
fixationPause = .5;
fixationColor = [0 0 0];
fixationSize = 2;

% gabor array parameters
numberOfGabors = 8;
arrayCenters = zeros(numberOfGabors,2);

SCREEN_HEIGHT = rect(4);
SCREEN_WIDTH = rect(3);

r = round(rect(4)./10);
g = round(.8*r);
gaborSize = g;


% stimulus motion parameters

movementSpeed = 3;
rotationSize = 30;
practiceRotationHandicap = 15;

jitterSize = 0;

% trial parameters

practiceTrials = 10;
breakEvery = 50;
timeLimit = 5;
feedbackPause = .5;

Screen('BlendFunction',w,GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%% Read in image

[gaborMatrix map alpha] = imread('single_gabor_75px.png');
gaborMatrix(:,:,4) = alpha(:,:);
gaborPatch = Screen('MakeTexture',w,gaborMatrix);

%% Counterbalancing
reps = 5; % Number of reps per angle condition per direction
trialList = [repmat(1:numberOfGabors,1,3*reps);...
    zeros(1,numberOfGabors*reps) ...
    repmat(90,1,numberOfGabors*reps)...
    repmat(270,1,numberOfGabors*reps)];
trialList = [trialList trialList; zeros(1,numberOfGabors*3*reps) ones(1,numberOfGabors*3*reps)];
trialList = trialList(:,randperm(length(trialList)));
practiceList = trialList(:,randperm(length(trialList)));
trialList = trialList';
practiceList = practiceList';

totalTrials = length(trialList);

%% Array Center Points

for i = 1:numberOfGabors
    arrayCenters(i,1) = r*cos((i-1)*(2*pi/numberOfGabors));
    arrayCenters(i,2) = r*sin((i-1)*(2*pi/numberOfGabors));
end

arrayCenters = round(arrayCenters);
centeredRects = [arrayCenters arrayCenters] + round(repmat([xc-g/2 yc-g/2 xc+g/2 yc+g/2],numberOfGabors,1));
centeredRects = centeredRects';

%% Experiment

%Instructions

rotation = round(rand(1,numberOfGabors)*360);
target = ceil(rand()*numberOfGabors);

proceed = 0;

sinceTwist = GetSecs;
twistModifier = 1;

phase = randi([0 360],numberOfGabors,1);

Screen('FillRect',w,bgcolor);
DrawFormattedText(w,'PRACTICE TRIALS','center','center');
Screen('Flip',w)
WaitSecs(1);

%% experiment
for k = -(practiceTrials+1):length(trialList)
    if k < 0
        direction = practiceList(-k,3);
        target = practiceList(-k,1);
        angle = practiceList(-k,2);
        trialNum = 'Practice';
    elseif k == 0
        direction = practiceList(practiceTrials,3);
        target = practiceList(practiceTrials,1);
        angle = practiceList(practiceTrials,2);
        trialNum = 'Practice';
    else
        direction = trialList(k,3);
        target = trialList(k,1);
        angle = trialList(k,2);
        trialNum = num2str(k);
    end
    arrayRects = [arrayCenters arrayCenters] + round(repmat([g/2+r-g/2 yc-g/2 g/2+r+g/2 yc+g/2],numberOfGabors,1));
    if direction
        arrayRects = arrayRects + repmat([-(2*r+g)+rect(3)-xBorder 0],numberOfGabors,2);
    else
        arrayRects = arrayRects + repmat([xBorder 0],numberOfGabors,2);
    end
    arrayRects = arrayRects';

    %% Gabors
    rotation = round(rand(1,numberOfGabors)*360);
    gaborPatch = Screen('MakeTexture',w,gaborMatrix);

    %% Trial code
    HideCursor
    jitter = round(((-1)^round(rand))*rand*jitterSize);
    changePoint = xc + jitter;
    changeOccurs = 0;
    trialOver = 0;

    phase = randi([0 360],numberOfGabors,1);   
    Screen('FillRect',w,bgcolor,rect);  
    Screen('DrawTextures',w,gaborPatch,[],arrayRects,rotation); 
    centerOfArray = [(min(arrayRects(1,:))+max(arrayRects(3,:)))/2 (min(arrayRects(2,:))+max(arrayRects(4,:)))/2];
    fixationRect = round([centerOfArray(1)-fixationSize centerOfArray(2)-fixationSize centerOfArray(1)+fixationSize centerOfArray(2)+fixationSize]);
    Screen('FillOval',w,fixationColor,fixationRect);  
    Screen('Flip',w);
    WaitSecs(fixationPause);   
    stimulusOnset = GetSecs;
    

    movementIncrement = repmat([movementSpeed 0 movementSpeed 0],numberOfGabors,1);
    movementIncrement = movementIncrement';
    fprintf(num2str(movementIncrement))
    while ~changeOccurs       
        Screen('FillRect',w,bgcolor,rect);       
        Screen('DrawTextures',w,gaborPatch,[],arrayRects,rotation);       
        centerOfArray = [(min(arrayRects(1,:))+max(arrayRects(3,:)))/2 (min(arrayRects(2,:))+max(arrayRects(4,:)))/2];
        fixationRect = round([centerOfArray(1)-fixationSize centerOfArray(2)-fixationSize centerOfArray(1)+fixationSize centerOfArray(2)+fixationSize]);
        Screen('FillOval',w,fixationColor,fixationRect); 
        Screen('Flip',w);
        fprintf([num2str(((-1)^(direction+1))*(centerOfArray(1)-changePoint)), '\n'])
        %counts down to zero by 3 then switches
        if ((-1)^(direction+1))*(centerOfArray(1)-changePoint) > 0     

            arrayRects = arrayRects + ((-1)^direction)*movementIncrement;
        else  % time for a change
            arrayRects = arrayRects + ((-1)^direction)*movementIncrement;
            changeOccurs = 1;
        end
    end
    
    %% Direction Change
    rotation(target) = rotation(target)+rotationSize;
    movementIncrement = repmat(movementSpeed.*[cosd(angle) sind(angle) cosd(angle) sind(angle)],numberOfGabors,1);
    movementIncrement = movementIncrement';
    fprintf(num2str(movementIncrement))

    bendTime = GetSecs - stimulusOnset;
        
    while ~trialOver
        Screen('FillRect',w,bgcolor,rect);
        Screen('DrawTextures',w,gaborPatch,[],arrayRects,rotation);
        centerOfArray = [(min(arrayRects(1,:))+max(arrayRects(3,:)))/2 (min(arrayRects(2,:))+max(arrayRects(4,:)))/2];
        fixationRect = round([centerOfArray(1)-fixationSize centerOfArray(2)-fixationSize centerOfArray(1)+fixationSize centerOfArray(2)+fixationSize]);
        Screen('FillOval',w,fixationColor,fixationRect);
        Screen('Flip',w);
        if max(arrayRects(3,:)) > rect(3)-xBorder || max(arrayRects(4,:)) > rect(4)-yBorder || min(arrayRects(3,:)) < xBorder || min(arrayRects(4,:)) < yBorder
            trialOver = 1;
        else
            arrayRects = arrayRects + ((-1)^direction)*movementIncrement;
        end
        
    end
    
    Screen('FillRect',w,bgcolor,rect);
    Screen('Flip',w);
    WaitSecs(.1);
    
    %% Probe
    
    ShowCursor;
    
    Screen('FillRect',w,bgcolor,rect);
    
    DrawFormattedText(w,'Click the patch that rotated:','center',yc-r-g);
    
    Screen('DrawTextures',w,gaborPatch,[],centeredRects,rotation);
    
    Screen('FillOval',w,fixationColor,[xc-fixationSize yc-fixationSize xc+fixationSize yc+fixationSize]);
    
    Screen('Flip',w);
    
    
    accuracy = 2;
    
    startTime = GetSecs;
    
    clicked = 0;
    
    while GetSecs-startTime<timeLimit && ~clicked
        [x y buttons] = GetMouse;
        if any(buttons)
            clicked = 1;
            timesUp = 1;
        end
    end
    
    correctRect = centeredRects(:,target);
    correctRect = correctRect';
    
    if clicked==1&&x>=correctRect(1)&&x<=correctRect(3)&&y>=correctRect(2)&&y<=correctRect(4)
        accuracy = 1;
        RT = GetSecs-startTime;
        Screen('FillRect',w,bgcolor,rect);
        DrawFormattedText(w,'Correct','center','center');
        Screen('Flip',w);
    elseif clicked==1
        accuracy = 0;
        Screen('FillRect',w,bgcolor,rect);
        DrawFormattedText(w,'Incorrect','center','center');
        RT = GetSecs-startTime;
        Screen('Flip',w);
    elseif clicked == 0
        Screen('FillRect',w,bgcolor,rect);
        DrawFormattedText(w,'Please respond more quickly','center','center');
        Screen('Flip',w);
        accuracy = 2;
        RT = timeLimit;
    end
    
    
    WaitSecs(feedbackPause);
    
    Screen('FillRect',w,bgcolor,rect);
    
    Screen('flip',w);
    
    %% Data File
    
    time = fix(clock);
    timestamp = [num2str(time(1)) '/' num2str(time(2)) '/' num2str(time(3)) '||' num2str(time(4)) ':' num2str(time(5)) ':' num2str(time(6))];
    
    directionName = directionNames{direction+1};
    
    % fprintf(dataFile,'%s\t%d\t%f\t%d\t%s\t%f\t%f\t%s\t%s\t%f\t%d\t%d\t%d\t%f\t%f\t%d\t%f\t%f\n',...
    %     trialNum,subject,seed,age,sex,r,g,timestamp,directionName,angle,target,movementSpeed,rotationSize,x,y,accuracy,RT,bendTime);

    
    
    Screen('Close');
    
end

fclose('all');



Screen('CloseAll');
