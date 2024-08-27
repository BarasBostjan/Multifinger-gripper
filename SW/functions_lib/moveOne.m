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