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