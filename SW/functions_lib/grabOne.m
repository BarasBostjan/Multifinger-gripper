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