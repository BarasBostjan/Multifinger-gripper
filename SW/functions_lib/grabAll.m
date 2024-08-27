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