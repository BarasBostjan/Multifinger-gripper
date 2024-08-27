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