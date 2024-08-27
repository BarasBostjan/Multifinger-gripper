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