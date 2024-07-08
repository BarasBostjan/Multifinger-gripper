clc;
clear all;

lib_name = 'dxl_x64_c';
% Load Libraries
if ~libisloaded(lib_name)
    [notfound, warnings] = loadlibrary(lib_name, 'dynamixel_sdk.h', 'addheader', 'port_handler.h', 'addheader', 'packet_handler.h');
end

 ADDR_TORQUE_ENABLE          = 64;
 ADDR_GOAL_POSITION          = 116;
 ADDR_PRESENT_POSITION       = 132;
 DXL_MINIMUM_POSITION_VALUE  = 0; % Dynamixel will rotate between this value
 DXL_MAXIMUM_POSITION_VALUE  = 4095; % and this value (note that the Dynamixel would not move when the position value is out of movable range. Check e-manual about the range of the Dynamixel you use.)
 BAUDRATE                    = 57600;
 global PROTOCOL_VERSION 
 PROTOCOL_VERSION            = 2.0;

 DEVICENAME                  = 'COM3'; 


 % Common Control Table Address and Data 
ADDR_OPERATING_MODE         = 11;          
OPERATING_MODE              = 3;            % value for operating mode for position control                                
TORQUE_ENABLE               = 1;            % Value for enabling the torque
TORQUE_DISABLE              = 0;            % Value for disabling the torque
DXL_MOVING_STATUS_THRESHOLD = 20;           % Dynamixel moving status threshold

COMM_SUCCESS                = 0;            % Communication Success result value
COMM_TX_FAIL                = -1001;        % Communication Tx Failed


% Initialize PortHandler Structs
% Set the port path
% Get methods and members of PortHandlerLinux or PortHandlerWindows
global port_num
port_num = portHandler(DEVICENAME);

% Initialize PacketHandler Structs
packetHandler();

index = 1;
dxl_comm_result = COMM_TX_FAIL;           % Communication result
dxl_goal_position = [DXL_MINIMUM_POSITION_VALUE DXL_MAXIMUM_POSITION_VALUE];         % Goal position

dxl_error = 0;                              % Dynamixel error
dxl_present_position = 0;                   % Present position


% Open port
if (openPort(port_num))
    fprintf('Succeeded to open the port!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to open the port!\n');
    input('Press any key to terminate...\n');
    return;
end


% Set port baudrate
if (setBaudRate(port_num, BAUDRATE))
    fprintf('Succeeded to change the baudrate!\n');
else
    unloadlibrary(lib_name);
    fprintf('Failed to change the baudrate!\n');
    input('Press any key to terminate...\n');
    return;
end

% setup
write1ByteTxRx(port_num, PROTOCOL_VERSION, 1, 11, 4); % Set operating mode (1-speed, 3-single rotation, 4-multi-turn rotation)
write2ByteTxRx(port_num, PROTOCOL_VERSION, 1, 44, 265); % Set velocity limit (default is 265)

write1ByteTxRx(port_num, PROTOCOL_VERSION, 2, 11, 4); % Set operating mode (1-speed, 3-single rotation, 4-multi-turn rotation)
write2ByteTxRx(port_num, PROTOCOL_VERSION, 2, 44, 265); % Set velocity limit (default is 265)

write1ByteTxRx(port_num, PROTOCOL_VERSION, 3, 11, 4); % Set operating mode (1-speed, 3-single rotation, 4-multi-turn rotation)
write2ByteTxRx(port_num, PROTOCOL_VERSION, 3, 44, 265); % Set velocity limit (default is 265)

global offset;
offset = [-7288 -16642 2943];  % indicates the number at which we want the reading to be zero. So if the motor in the fully closed position displays -23379, we subtract this value from the offset to show 0. 
global max;
max = [23608  23608 23608];  % indicates the maximum difference between the value on the motor in the most closed and most open finger positions.
                            % Generally, these values are not the same, but it is ideal if they are (Below are 2 functions for manipulating these values)
global defaultSpeed;
defaultSpeed = 50;   % setting the default speed used by the gripper if the user does not specify specific movement speeds in the functions


% Enable Dynamixel Torque
write1ByteTxRx(port_num, PROTOCOL_VERSION, 1, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 2, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 3, ADDR_TORQUE_ENABLE, TORQUE_ENABLE);
dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
else
    fprintf('Dynamixel has been successfully connected \n');
end

% Main

%{
calibrate(1)
calibrate(2)
calibrate(3)
offset
max
%}


%{
moveAll(30)
moveAll(40,20,10)
moveAll(10,40,20,100)
moveAll(0)
%}

%{
grabAll(50)
pause(2)
moveAll(0)
grabAll(30,50,100)
pause(2)
moveAll(0)
grabAll(50, 50, 50, 80)
pause(2)
moveAll(0)
grabAll(50, 50, 50, 30, 50, 70)
pause(2)
moveAll(0)
%}

%{
grabAll(70)
pause(10)
moveAll(0)
%}

%{
calibrate(1)
calibrate(2)
calibrate(3)
calculateEqualMinimalMax()
offset
max
%}


% Disable Dynamixel Torque
write1ByteTxRx(port_num, PROTOCOL_VERSION, 1, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 2, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
write1ByteTxRx(port_num, PROTOCOL_VERSION, 3, ADDR_TORQUE_ENABLE, TORQUE_DISABLE);
dxl_comm_result = getLastTxRxResult(port_num, PROTOCOL_VERSION);
dxl_error = getLastRxPacketError(port_num, PROTOCOL_VERSION);
if dxl_comm_result ~= COMM_SUCCESS
    fprintf('%s\n', getTxRxResult(PROTOCOL_VERSION, dxl_comm_result));
elseif dxl_error ~= 0
    fprintf('%s\n', getRxPacketError(PROTOCOL_VERSION, dxl_error));
end

% Close port
closePort(port_num);

% Unload Library
unloadlibrary(lib_name);

close all;
clear all;
disp('konec programa')




%Functions
function [] = calibrate(ID)  %finger calibration -> the finger moves to both of its extreme positions, thus determining the parameters "offset" and "max" for the specific finger
    global max    %declaration of global variables
    global offset
    global port_num
    global PROTOCOL_VERSION 
    offset(ID) = 0;     %clears the previous offset and sets it to 0;
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 1);   %set Operating Mode to Velocity control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - 100);  %starts moving
    i = 0;
    torque = 0;
    while i < 30   %waits for no friction (let's assume the finger is stuck in one extreme position and the measured torque is still high even though we are moving the finger away from the extreme)
        torque = readTorque(ID);    %reads the torque value
        if torque < 60     %increments the counter by 1 every time the torque is less than the specified value, otherwise resets the counter
            i = i + 1;
        else
            i = 0;
        end
    end
    torque = 0;   
    while torque < 150   %starts searching for the lower limit, waits for the torque to increase above the minimum specified torque
        torque = readTorque(ID);
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0);   %stops the motor
    pause(0.2)   % waits for it to stabilize (so that the motor actually stops)
    offset(ID) = readRotation(ID);  %sets the lower limit (considering that the offset = 0 until now, which means the readRotation function still returns the actual value sent by the motor)
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 100);   %starts moving in the opposite direction
    i = 0;
    torque = 0;
    while i < 30   %waits to move away from the lower limit (similar to the above description)
        torque = readTorque(ID);   %works the same as above, just in the opposite direction
        if torque < 60
            i = i + 1;
        else
            i = 0;
        end
    end
    torque = 0;   %starts searching for the upper limit
    while torque < 150   %starts searching for the upper limit, waits for the torque to increase above the minimum specified torque
        torque = readTorque(ID);
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0)   %stops the motor
    pause(0.2) %čaka, da se umiri
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - 100);  %starts moving
    i = 0;
    while i < 30   %waits for no friction (similar to the previous two cases above). We don't want the basic finger position to be when it is stuck in the extreme, so we move it away from the extreme to avoid unwanted torque that would interfere with other functions later
        torque = readTorque(ID);
        if torque < 60
            i = i + 1;
        else
            i = 0;
        end
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0)   %stops the motor
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 4);   %set Operating Mode to Extended Position Control Mode
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
    max(ID) = readRotation(ID);  %sets the difference between the lower and upper limits (here the readRotation function already has the offset variable set, so it really measures from position 0 to the maximum position, which is indeed the difference between the maximum and minimum values)
end



function [] = moveOne(ID, moveTo, speed)   %Moves one finger to the desired position. Set the motor ID, desired position (in percentages), optional speed (in percentages)
    global max    %declares global variables
    global offset
    global port_num
    global PROTOCOL_VERSION
    global defaultSpeed
    switch nargin
        case 2    %you can enter only the motor ID and desired position, the speed is set to the default speed
            speed = defaultSpeed; 
        case 3    %you can enter all 3 possible parameters
        otherwise
            disp('Invalid number of inputs')   %if you enter another number of parameters, the function reports an error in the console
    end
    position = max(ID) * (100 - moveTo) / 100 + offset(ID);   %converts the position in percentages to a position that the motor understands. It also considers calibration parameters
    if position < 0
        position = position + 4294967296;   %the motor understands only the signed binary representation, so we need to add one "period" to the negative number
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 112, speed / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 116, position);  %sets the position
    pause(0.1);   %waits for the motor to start rotating
    movement = 1;
    while movement == 1   %repeats while the movement indicator is 1
        movement = read1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 122);   %reads the movement status, which is 0 or 1. Since the program is faster than the mechanics, previous waiting is needed
    end
    %when the movement is over, the desired position is reached, and this is the end of this function
end

%Grabs an object with one finger. The user specifies the motor ID, the desired maximum torque (in percentages), the optional speed (in percentages)
function [] = grabOne(ID, maxTorque, speed)    %WARNING: the maximum desired torque can be set above 100%, which may lead to mechanical damage
    global port_num    %sets global variables
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 2         %you can enter only the motor ID and desired position, the speed is set to the default speed
            speed = defaultSpeed;
        case 3         %you can enter all 3 possible parameters
        otherwise
            disp('Invalid number of inputs')     %if you enter another number of parameters, the function reports an error in the console
    end
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 1);   %set Operating Mode to Velocity control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 4294967295 - speed / 100 * 265);  %starts moving
    torque = 0;
    pause(0.3);   %waits for the torque spike to pass before the motor starts moving at a constant speed
    while torque < maxTorque * 2.5     %waits for the torque to reach the desired value (2.5 is the conversion from percentages to torque)
        torque = readTorque(ID);
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 104, 0);  %stops the motor
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 0);   %disable torque
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 11, 4);   %set Operating Mode to Position control
    write1ByteTxRx(port_num, PROTOCOL_VERSION , ID, 64, 1);   %enable torque
end



function [currentRotation] = readRotation(ID)     %reads the current rotation value on the motor (considers calibration parameters)
    global offset;      %declares global variables
    global port_num;
    global PROTOCOL_VERSION ;
    rotation = read4ByteTxRx(port_num, PROTOCOL_VERSION , ID, 132);     %reads the rotation from the motor
    if rotation > 2147483647
        currentRotation = rotation - 4294967295 - offset(ID);      %if it reads a negative signed number, it first converts it to a normal negative decimal number and then considers the offset
    else
        currentRotation = rotation - offset(ID);     %subtracts the offset from the read rotation
    end
end

function [torque] = readTorque(ID)   %reads the absolute torque value
    global port_num;            %declares global variables
    global PROTOCOL_VERSION; 
    readTorque = read2ByteTxRx(port_num, PROTOCOL_VERSION , ID, 126);    %reads the torque value
    if readTorque > 32767     %if the read torque is negative in signed number, it converts it to a positive decimal number, otherwise leaves the read torque unchanged
       torque = 65535 - readTorque;
    else
       torque = readTorque;
    end
end
   

%The function grabAll grabs with all motors at once. You can enter either just one torque value, or 3 torque values, or 3 torque values and speed, or 3 torque values and 3 speeds. All values are in percentages. If we don't want to move any of the 3 fingers, we set the speed or torque to 0 (It's better to set the speed to zero because in this case, the motor won't activate at all).
function [] = grabAll(maxTorque1, maxTorque2, maxTorque3, speed1, speed2, speed3)    
    global port_num             %declares global variables
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 1   %if only one value is entered, this value represents the maximum desired torque for gripping and will be used on all motors. The speed of the motors will be set to the default speed
            maxTorque2 = maxTorque1;
            maxTorque3 = maxTorque1;
            speed1 = defaultSpeed;
            speed2 = defaultSpeed;
            speed3 = defaultSpeed;
        case 3   %if 3 values are entered, these are the values for the maximum desired torque for each motor separately. The speed of the motors will be set to the default speed
            speed1 = defaultSpeed;
            speed2 = defaultSpeed;
            speed3 = defaultSpeed;
        case 4   %if 4 values are entered, the first 3 values are the maximum desired torque for each motor separately. The last value is the speed value of the motors and will be used on all motors
            speed2 = speed1;
            speed3 = speed1;
        case 6   %if 6 values are entered, each motor gets its value of desired maximum torque and speed
        otherwise
            disp('Invalid number of inputs')     %if you enter another number of parameters, the function reports an error in the console
    end
    %Prepares the motors for Velocity control if the desired speed is greater than 0.
    %If we set the speed = 0 for any motor, this motor will not be set to operate
    if speed1 > 0
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 0);   %disable torque
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 11, 1);   %set Operating Mode to Velocity control
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 1);   %enable torque
        write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 104, 4294967295 - speed1 / 100 * 264);  %starts moving
        a = 0;
    else
        a = 1;
    end
    if speed2 > 0
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 0);   %disable torque
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 11, 1);   %set Operating Mode to Velocity control
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 1);   %enable torque
        write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 104, 4294967295 - speed2 / 100 * 264);  %starts moving
        b = 0;
    else
        b = 1;
    end
    if speed3 > 0
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 0);   %disable torque
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 11, 1);   %set Operating Mode to Velocity control
        write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 1);   %enable torque
        write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 104, 4294967295 - speed3 / 100 * 264);  %starts moving
        c = 0;
    else
        c = 1;
    end
    torque1 = 0;
    torque2 = 0;
    torque3 = 0;
    pause(0.3);  %waits for the torque spike to pass
    while a == 0 || b == 0 || c == 0    %a, b, and c are indicators if the movement has already ended. Inactive motors are set to 1 before the loop starts.
        torque1 = readTorque(1);   %reads all 3 torques
        torque2 = readTorque(2);
        torque3 = readTorque(3);
        if torque1 >= maxTorque1 * 2.5 && a == 0    %waits for the desired motor torque, where the motor must still be active
            write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 104, 0);  %stops the motor
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 0);   %disable torque
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 11, 4);   %set Operating Mode to Velocity control
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 64, 1);   %enable torque
            a = 1;
        end 
        if torque2 >= maxTorque2 * 2.5 && b == 0    %čaka na želeni navor motorja, pri čemer mora biti motor še aktiven
            write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 104, 0);  %stops the motor
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 0);   %disable torque
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 11, 4);   %set Operating Mode to Velocity control
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 64, 1);   %enable torque
            b = 1;
        end
        if torque3 >= maxTorque3 * 2.5 && c == 0    %čaka na želeni navor motorja, pri čemer mora biti motor še aktiven
            write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 104, 0);  %stops the motor
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 0);   %disable torque
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 11, 4);   %set Operating Mode to Velocity control
            write1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 64, 1);   %enable torque
            c = 1;
        end
    end
end



%The function moveAll moves all motors to the desired position. You can enter only one position, which moves all motors to the same position, 3 positions for each motor separately, and you can also specify the speed of movement with the 4th entered value. All parameters are entered in percentages. Remember: Only one speed can be set, as the function determines this speed only for the finger that needs to make the most significant move, and sets a new speed for the other fingers, which is less than or equal to the desired speed, so that all motors start and finish moving at the same time.
function [] = moveAll(position1, position2, position3, speed)    
    global max              %declares global variables
    global offset
    global port_num
    global PROTOCOL_VERSION 
    global defaultSpeed
    switch nargin
        case 1     %if only one value is entered, this value represents the desired position for all fingers. The speed is set to the default speed
            position2 = position1;
            position3 = position1;
            speed = defaultSpeed;
        case 3     %If 3 values are entered, these are the 3 position values for each finger separately. The speed is set to the default speed
            speed = defaultSpeed;
        case 4     %If 4 values are entered, the first 3 values are the position values for each finger separately. The 4th value sets the speed of movement of the fingers
        otherwise
            disp('Invalid number of inputs')            %if you enter another number of parameters, the function reports an error in the console
    end
    location1 = max(1) * (100 - position1) / 100 + offset(1);            %converts the position in percentages to a position that the motor understands. It also considers calibration parameters
    location2 = max(2) * (100 - position2) / 100 + offset(2);
    location3 = max(3) * (100 - position3) / 100 + offset(3);
    currentLocation1 = readRotation(1) + offset(1);      %reads the current finger location (The offset is added because the positions in the previous lines are already prepared for motor movement, readRotation already considers the offset. Simply put: either the offset is added in the previous lines and these lines, or it isn't in both.)
    currentLocation2 = readRotation(2) + offset(2); 
    currentLocation3 = readRotation(3) + offset(3); 
    delta1 = abs(location1 - currentLocation1);     %calculates the change in position between the current and final position
    delta2 = abs(location2 - currentLocation2); 
    delta3 = abs(location3 - currentLocation3); 
    if delta1 >= delta2 && delta1 >= delta3       %finds the finger that needs to make the most significant move and assigns it the desired speed. The other two fingers are proportionally assigned a speed based on the change in position
        speed1 = speed;
        speed2 = delta2 / delta1 * speed;
        speed3 = delta3 / delta1 * speed;
    elseif delta2 >= delta1 && delta2 >= delta3
        speed2 = speed;
        speed1 = delta1 / delta2 * speed;
        speed3 = delta3 / delta2 * speed;
    else
        speed3 = speed;
        speed1 = delta1 / delta3 * speed;
        speed2 = delta2 / delta3 * speed;
    end
    if location1 < 0    %If the location is negative, add "period" because the motor understands only binary signed numbers
        location1 = location1 + 4294967296;
    end
    if location2 < 0
        location2 = location2 + 4294967296;
    end
    if location3 < 0
        location3 = location3 + 4294967296;
    end
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 112, speed1 / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 112, speed2 / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 112, speed3 / 100 * 265);  %sets the speed
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 1, 116, location1);  %sets the position
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 2, 116, location2);  %sets the position
    write4ByteTxRx(port_num, PROTOCOL_VERSION , 3, 116, location3);  %sets the position
    pause(0.1);   %waits for the motors to start moving (similar to moveOne)
    movement1 = 1;
    movement2 = 1;
    movement3 = 1;
    while movement1 == 1 || movement2 == 1 || movement3 == 1    %waits for all motors to stop moving
        movement1 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 1, 122);
        movement2 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 2, 122);
        movement3 = read1ByteTxRx(port_num, PROTOCOL_VERSION , 3, 122);
    end
end

%During calibration, each motor gets its max or its difference between the maximum and minimum positions. For various reasons, these maxes can be very different from each other. This can mean that later the gripper may behave somewhat oddly, e.g., if we set the same position for all fingers, the fingers may not be in the same position. The functions calculateEqualMinimalMax and calculateEqualMax correct this by setting the same max for all fingers. These functions are necessary because the 0 position of the fingers is defined when they are most closed, and 0% during movements is when the finger is most open. Thus, we cannot simply set all maxes to the same value but must also appropriately change the offsets.
function [] = calculateEqualMinimalMax()     %sets all maxes to the max of the finger with the smallest max value. 
    global offset           %declares global variables
    global max
    if max(1) <= max(2) && max(1) <= max(3)     %finds the smallest max
        offset(2) = offset(2) + max(2) - max(1);    %changes the offsets of the other two fingers by the difference between the old and new max
        offset(3) = offset(3) + max(3) - max(1);
        max(2) = max(1);            %sets the other maxes to the new max
        max(3) = max(1);
    elseif max(2) <= max(1) && max(2) <= max(3)
        offset(1) = offset(1) + max(1) - max(2);
        offset(3) = offset(3) + max(3) - max(2);
        max(1) = max(2);
        max(3) = max(2);
    else
        offset(1) = offset(1) + max(1) - max(3);
        offset(2) = offset(2) + max(2) - max(3);
        max(1) = max(3);
        max(2) = max(3);
    end
end

function [] = calculateEqualMax(newMax)    %sets all maxes to the desired max (typical max is around 24000)
    global offset           %declares global variables
    global max
    offset(1) = offset(1) + max(1) - newMax;   %changes the offsets of all fingers by the difference between the old and new max   
    offset(2) = offset(2) + max(2) - newMax;
    offset(3) = offset(3) + max(3) - newMax;
    max(1) = newMax;          %sets the maxes to the new max
    max(2) = newMax;
    max(3) = newMax;
 end 
