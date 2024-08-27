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
